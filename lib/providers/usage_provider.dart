import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/services/auth_storage_service.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/services/usage_remote_service.dart";
import "package:life_pattern_tracker/services/usage_stats_service.dart";
import "package:life_pattern_tracker/services/usage_storage_service.dart";

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

  Future<void> initialize() async {
    try {
      final hasPermission = await _statsService.hasUsagePermission();
      final history = await _storageService.getAllDays();
      state = state.copyWith(
        initialCheckComplete: true,
        hasPermission: hasPermission,
        history: history,
        clearError: true,
      );
      if (hasPermission) {
        await refreshToday();
      }
    } catch (e) {
      state = state.copyWith(initialCheckComplete: true, error: e.toString());
    }
  }

  Future<void> openUsageSettings() => _statsService.openUsageAccessSettings();

  Future<void> checkPermission() async {
    final permission = await _statsService.hasUsagePermission();
    state = state.copyWith(hasPermission: permission);
    if (permission) {
      await refreshToday();
    }
  }

  Future<void> refreshToday() async {
    state = state.copyWith(syncing: true, clearError: true);
    try {
      final today = await _statsService.getUsageStats();
      if (today != null) {
        await _storageService.saveDay(today);
      }
      final history = await _storageService.getAllDays();
      state = state.copyWith(
        syncing: false,
        today: today ?? state.today,
        history: history,
      );
      await _syncToCloud(today);
    } catch (e) {
      state = state.copyWith(syncing: false, error: e.toString());
    }
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
