import "dart:math";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
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
  UsageNotifier(this._statsService, this._storageService) : super(const UsageState()) {
    initialize();
  }

  final UsageStatsService _statsService;
  final UsageStorageService _storageService;

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
        today: today,
        history: history,
      );
    } catch (e) {
      state = state.copyWith(syncing: false, error: e.toString());
    }
  }

  int averageDailyMinutes() {
    if (state.history.isEmpty) return 0;
    final total = state.history.fold<int>(0, (sum, day) => sum + day.totalScreenTime);
    return (total / state.history.length).round();
  }

  int productivityScore() {
    final daily = state.today?.totalScreenTime ?? 0;
    final score = 100 - (daily ~/ 6);
    return score.clamp(0, 100).toInt();
  }

  int focusScore() {
    final apps = state.today?.appUsages ?? const [];
    final socialMins = apps
        .where((app) =>
            app.category.toLowerCase().contains("social") ||
            app.appName.toLowerCase().contains("instagram") ||
            app.appName.toLowerCase().contains("facebook") ||
            app.appName.toLowerCase().contains("tiktok"))
        .fold<int>(0, (sum, app) => sum + app.usageTime);
    final score = 100 - min(90, socialMins ~/ 3);
    return score.clamp(0, 100).toInt();
  }
}

final usageProvider = StateNotifierProvider<UsageNotifier, UsageState>((ref) {
  return UsageNotifier(
    ref.read(usageStatsServiceProvider),
    ref.read(usageStorageServiceProvider),
  );
});
