import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";

class DashboardViewState {
  const DashboardViewState({
    required this.metrics,
    required this.syncing,
    this.usageError,
  });

  final DashboardMetrics metrics;
  final bool syncing;
  final String? usageError;

  factory DashboardViewState.initial() => DashboardViewState(
        metrics: DashboardMetricsService.build(
          history: const [],
          habits: HabitTrackerState.loading(),
        ),
        syncing: false,
      );

  DashboardViewState copyWith({
    DashboardMetrics? metrics,
    bool? syncing,
    String? usageError,
    bool clearError = false,
  }) {
    return DashboardViewState(
      metrics: metrics ?? this.metrics,
      syncing: syncing ?? this.syncing,
      usageError: clearError ? null : (usageError ?? this.usageError),
    );
  }
}

class DashboardController extends StateNotifier<DashboardViewState> {
  DashboardController(this._ref) : super(DashboardViewState.initial()) {
    _recomputeMetrics();
    _ref.listen(usageProvider, (_, __) => _recomputeMetrics());
    _ref.listen(habitTrackerProvider, (_, __) => _recomputeMetrics());
  }

  final Ref _ref;

  void _recomputeMetrics() {
    final usage = _ref.read(usageProvider);
    final habits = _ref.read(habitTrackerProvider);
    state = state.copyWith(
      metrics: DashboardMetricsService.build(
        today: usage.today,
        history: usage.history,
        habits: habits,
      ),
      syncing: usage.syncing,
      usageError: usage.error,
      clearError: usage.error == null,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(syncing: true, clearError: true);
    await Future.wait<void>([
      _ref.read(usageProvider.notifier).refreshToday(),
      _ref.read(habitTrackerProvider.notifier).refresh(),
    ]);
    _recomputeMetrics();
    state = state.copyWith(syncing: false);
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardController, DashboardViewState>((ref) {
  return DashboardController(ref);
});
