import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/insight_models.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/services/gemini_service.dart";
import "package:life_pattern_tracker/services/insights_engine.dart";

class InsightsViewState {
  const InsightsViewState({
    required this.ready,
    required this.insights,
    required this.aiLoading,
    required this.aiUsesGemini,
  });

  final bool ready;
  final InsightsState insights;
  final bool aiLoading;
  final bool aiUsesGemini;

  factory InsightsViewState.loading() => InsightsViewState(
        ready: false,
        insights: InsightsEngine.build(
          metrics: DashboardMetricsService.build(history: const [], habits: HabitTrackerState.loading()),
          habits: HabitTrackerState.loading(),
        ),
        aiLoading: true,
        aiUsesGemini: false,
      );
}

class InsightsNotifier extends StateNotifier<InsightsViewState> {
  InsightsNotifier(this._ref) : super(InsightsViewState.loading()) {
    _ref.listen(usageProvider, (_, __) => _rebuildCalculated());
    _ref.listen(habitTrackerProvider, (_, __) => _rebuildCalculated());
    _rebuildCalculated();
    Future.microtask(_loadAiTips);
  }

  final Ref _ref;

  DashboardMetrics _metrics() {
    final usage = _ref.read(usageProvider);
    final habits = _ref.read(habitTrackerProvider);
    return DashboardMetricsService.build(
      today: usage.today,
      history: usage.history,
      habits: habits,
    );
  }

  void _rebuildCalculated() {
    final habits = _ref.read(habitTrackerProvider);
    final metrics = _metrics();
    state = InsightsViewState(
      ready: habits.ready,
      insights: InsightsEngine.build(
        metrics: metrics,
        habits: habits,
        aiTips: state.insights.aiTips,
      ),
      aiLoading: state.aiLoading,
      aiUsesGemini: state.aiUsesGemini,
    );
  }

  Future<void> refresh() async {
    state = InsightsViewState(
      ready: state.ready,
      insights: state.insights,
      aiLoading: true,
      aiUsesGemini: state.aiUsesGemini,
    );
    await Future.wait<void>([
      _ref.read(usageProvider.notifier).refreshToday(),
      _ref.read(habitTrackerProvider.notifier).refresh(),
    ]);
    _rebuildCalculated();
    await _loadAiTips();
  }

  Future<void> _loadAiTips() async {
    final metrics = _metrics();
    final habits = _ref.read(habitTrackerProvider);
    final habitPct = habits.ready ? habits.weeklyProgressPercent : 0;

    if (!GeminiService.isConfigured) {
      state = InsightsViewState(
        ready: habits.ready,
        insights: InsightsEngine.build(
          metrics: metrics,
          habits: habits,
          aiTips: InsightsEngine.fallbackAiTips(metrics, habitPct),
        ),
        aiLoading: false,
        aiUsesGemini: false,
      );
      return;
    }

    try {
      final lines = await GeminiService.generateInsightTips(
        todayMinutes: metrics.screenMinutes,
        averageMinutes: metrics.averageMinutes,
        focusScore: metrics.focusScore,
        productivityScore: metrics.productivityScore,
        habitCompletionPercent: habitPct,
        moodAverage: metrics.moodAverage,
        ruleSummary: metrics.ruleInsights.join(" "),
      );
      final tips = InsightsEngine.tipsFromLines(lines);
      state = InsightsViewState(
        ready: habits.ready,
        insights: InsightsEngine.build(
          metrics: metrics,
          habits: habits,
          aiTips: tips.isEmpty
              ? InsightsEngine.fallbackAiTips(metrics, habitPct)
              : tips,
        ),
        aiLoading: false,
        aiUsesGemini: true,
      );
    } catch (_) {
      state = InsightsViewState(
        ready: habits.ready,
        insights: InsightsEngine.build(
          metrics: metrics,
          habits: habits,
          aiTips: InsightsEngine.fallbackAiTips(metrics, habitPct),
        ),
        aiLoading: false,
        aiUsesGemini: false,
      );
    }
  }
}

final insightsProvider =
    StateNotifierProvider<InsightsNotifier, InsightsViewState>((ref) {
  return InsightsNotifier(ref);
});
