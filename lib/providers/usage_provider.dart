import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/services/auth_storage_service.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";
import "package:life_pattern_tracker/services/usage_remote_service.dart";
import "package:life_pattern_tracker/services/usage_stats_service.dart";
import "package:life_pattern_tracker/services/usage_storage_service.dart";
import "package:life_pattern_tracker/utils/today_date.dart";

const String kUsageOwnerEmailKey = "usage_owner_email";
const String kUsageCloudPurgedKey = "usage_cloud_purged_v3";

final usageStatsServiceProvider = Provider<UsageStatsService>((ref) => UsageStatsService());
final usageStorageServiceProvider = Provider<UsageStorageService>((ref) => UsageStorageService());

class UsageState {
  const UsageState({
    this.syncing = false,
    this.initialCheckComplete = false,
    this.hasPermission = false,
    this.today,
    this.history = const [],
    this.error,
  });

  /// True while fetching usage from the native bridge (pull-to-refresh / sync).
  final bool syncing;
  /// False until the first permission + storage read finishes (avoids wrong home route).
  final bool initialCheckComplete;
  final bool hasPermission;
  final DailyUsageModel? today;
  final List<DailyUsageModel> history;
  final String? error;

  UsageState copyWith({
    bool? syncing,
    bool? initialCheckComplete,
    bool? hasPermission,
    DailyUsageModel? today,
    List<DailyUsageModel>? history,
    String? error,
    bool clearError = false,
  }) {
    return UsageState(
      syncing: syncing ?? this.syncing,
      initialCheckComplete: initialCheckComplete ?? this.initialCheckComplete,
      hasPermission: hasPermission ?? this.hasPermission,
      today: today ?? this.today,
      history: history ?? this.history,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UsageNotifier extends StateNotifier<UsageState> {
  UsageNotifier(
    this._statsService,
    this._storageService,
    this._authStorage,
    this._usageRemote,
  ) : super(const UsageState()) {
    initialize();
  }

  final UsageStatsService _statsService;
  final UsageStorageService _storageService;
  final AuthStorageService _authStorage;
  final UsageRemoteService _usageRemote;
  String? _lastRefreshDayKey;

  Future<void> initialize() async {
    try {
      final hasPermission = await _statsService.hasUsagePermission();
      await _purgeLegacyCloudUsageOnce();
      await _clearUsageIfAccountChanged();
      state = state.copyWith(
        initialCheckComplete: true,
        hasPermission: hasPermission,
        clearError: true,
      );
      if (hasPermission) {
        await refreshToday();
      } else {
        state = state.copyWith(history: const [], today: null);
      }
    } catch (e) {
      state = state.copyWith(initialCheckComplete: true, error: e.toString());
    }
  }

  /// Call after sign-in: drop cached cloud usage and reload from Usage Access only.
  Future<void> applyDeviceOnlyOnSignIn() async {
    await _clearUsageIfAccountChanged();
    if (state.hasPermission) {
      await refreshToday();
    } else {
      state = state.copyWith(history: const [], today: null, clearError: true);
    }
  }

  Future<void> openUsageSettings() => _statsService.openUsageAccessSettings();

  Future<void> openApplicationSettings() => _statsService.openApplicationSettings();

  Future<String> applicationLabel() => _statsService.getApplicationLabel();

  Future<String> usageAccessHint() => _statsService.getUsageAccessHint();

  Future<void> checkPermission() async {
    final permission = await _statsService.hasUsagePermission();
    state = state.copyWith(hasPermission: permission);
    if (permission) {
      await refreshToday();
    }
  }

  Future<void> _purgeLegacyCloudUsageOnce() async {
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return;
    final box = Hive.box<dynamic>(kAppSettingsBoxName);
    if (box.get(kUsageCloudPurgedKey) == true) return;
    await _storageService.clearAll();
    await box.put(kUsageCloudPurgedKey, true);
  }

  Future<void> _clearUsageIfAccountChanged() async {
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return;
    final email = await _authStorage.getSessionEmail();
    final normalized = email?.trim().toLowerCase() ?? "";
    final box = Hive.box<dynamic>(kAppSettingsBoxName);
    final previous = (box.get(kUsageOwnerEmailKey) as String?)?.trim().toLowerCase() ?? "";
    if (normalized.isEmpty) return;
    if (previous.isNotEmpty && previous != normalized) {
      await _storageService.clearAll();
    }
    await box.put(kUsageOwnerEmailKey, normalized);
  }

  Future<void> refreshToday() async {
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final fetched = await _statsService.getUsageStats();
      final today = _resolveTodayModel(fetched);
      if (today != null) {
        await _storageService.saveDay(today);
        _lastRefreshDayKey = TodayDate.dayKey;
      }
      final history = await _storageService.getAllDays();
      final resolved = today ?? _todayFromHistory(history);
      state = state.copyWith(
        syncing: false,
        today: resolved,
        history: history,
      );
      await _syncToCloud(resolved);
    } catch (e) {
      state = state.copyWith(syncing: false, error: e.toString());
    }
  }

  /// Refresh when the calendar day changes (midnight) or returning to the app.
  Future<void> refreshIfDayChanged() async {
    if (_lastRefreshDayKey != TodayDate.dayKey) {
      final stale = state.today;
      if (stale != null && !TodayDate.isSameLocalDay(stale.date)) {
        state = state.copyWith(today: null);
      }
      if (state.hasPermission) {
        await refreshToday();
      }
    }
  }

  DailyUsageModel? _resolveTodayModel(DailyUsageModel? model) {
    if (model == null) return null;
    if (!TodayDate.isSameLocalDay(model.date)) return null;
    // Reject impossible totals cached by an older buggy build (e.g. 77h screen time).
    if (model.totalScreenTime > 24 * 60) return null;
    return model;
  }

  DailyUsageModel? _todayFromHistory(List<DailyUsageModel> history) {
    for (var i = history.length - 1; i >= 0; i--) {
      final day = history[i];
      if (!TodayDate.isSameLocalDay(day.date)) continue;
      if (day.totalScreenTime > 24 * 60) continue;
      return day;
    }
    return null;
  }

  Future<void> _syncToCloud(DailyUsageModel? today) async {
    if (!_usageRemote.isConfigured || today == null) return;
    final email = await _authStorage.getSessionEmail();
    if (email == null) return;
    await _usageRemote.uploadUsageDay(userEmail: email, day: today);
  }

  int averageDailyMinutes() {
    if (state.history.isEmpty) return 0;
    final total = state.history.fold<int>(0, (sum, day) => sum + day.totalScreenTime);
    return (total / state.history.length).round();
  }

  int productivityScore() => DashboardMetricsService.productivityScoreForToday(state.today);

  int focusScore() => DashboardMetricsService.focusScoreForToday(state.today);

  /// Daily screen-time goal for progress bar (8 hours).
  static const int dailyScreenTimeGoalMinutes =
      DashboardMetricsService.dailyScreenTimeGoalMinutes;

  double screenTimeProgressFraction() {
    final minutes = state.today?.totalScreenTime ?? 0;
    if (dailyScreenTimeGoalMinutes <= 0) return 0;
    return (minutes / dailyScreenTimeGoalMinutes).clamp(0.0, 1.0);
  }

  double productivityProgressFraction() => productivityScore() / 100;

  double focusProgressFraction() => focusScore() / 100;
}

final usageRemoteServiceProvider = Provider<UsageRemoteService>((ref) => UsageRemoteService());

final usageProvider = StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  return UsageNotifier(
    ref.read(usageStatsServiceProvider),
    ref.read(usageStorageServiceProvider),
    ref.read(authStorageServiceProvider),
    ref.read(usageRemoteServiceProvider),
  );
});
