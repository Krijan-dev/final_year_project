import "package:flutter/material.dart";
import "package:life_pattern_tracker/models/insight_models.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

/// Rule-based Insights tab content from usage + habit tracker.
abstract final class InsightsEngine {
  static InsightsState build({
    required DashboardMetrics metrics,
    required HabitTrackerState habits,
    List<AiInsightTip> aiTips = const [],
  }) {
    final habitPct = habits.ready ? habits.weeklyProgressPercent : 0;
    final moodAvg = habits.ready && habits.averageMood > 0 ? habits.averageMood : null;
    final exercisePct = _habitWeekPercent(habits, "exercise");
    final waterPct = _habitWeekPercent(habits, "water");
    final sleepPct = _habitWeekPercent(habits, "sleep");

    final healthRisk = _healthRiskScore(
      metrics: metrics,
      habitPct: habitPct,
      moodAvg: moodAvg,
    );

    final physical = _physicalWellness(exercisePct, waterPct, sleepPct, habitPct);
    final mental = _mentalWellness(moodAvg, metrics.focusScore);
    final overall = ((physical + mental) / 2).round().clamp(0, 100);

    return InsightsState(
      healthRiskLabel: _riskLabel(healthRisk),
      healthRiskScore: healthRisk,
      healthMetrics: _healthMetrics(
        metrics: metrics,
        habitPct: habitPct,
        moodAvg: moodAvg,
        exercisePct: exercisePct,
        sleepPct: sleepPct,
      ),
      overallWellnessScore: overall,
      wellnessScores: [
        WellnessScoreItem(
          label: "Physical",
          score: physical,
          background: const Color(0xFFDCFCE7),
          foreground: const Color(0xFF16A34A),
        ),
        WellnessScoreItem(
          label: "Mental",
          score: mental,
          background: const Color(0xFFDBEAFE),
          foreground: const Color(0xFF2563EB),
        ),
      ],
      recommendations: _ruleRecommendations(
        metrics: metrics,
        habitPct: habitPct,
        moodAvg: moodAvg,
        exercisePct: exercisePct,
        waterPct: waterPct,
      ),
      aiTips: aiTips,
      weeklyTrends: _weeklyTrends(metrics: metrics, habitPct: habitPct, moodAvg: moodAvg),
    );
  }

  static int _habitWeekPercent(HabitTrackerState habits, String id) {
    if (!habits.ready) return 0;
    for (final h in habits.habits) {
      if (h.id == id) return h.percent;
    }
    return 0;
  }

  static int _healthRiskScore({
    required DashboardMetrics metrics,
    required int habitPct,
    required double? moodAvg,
  }) {
    var risk = 10;
    if (!metrics.hasUsageData) risk += 25;
    if (metrics.screenMinutes > DashboardMetricsService.dailyScreenTimeGoalMinutes) {
      risk += 25;
    } else if (metrics.screenDiffMinutes > 45) {
      risk += 15;
    }
    if (metrics.focusScore < 45) risk += 15;
    if (metrics.productivityScore < 45) risk += 10;
    if (habitPct < 40) risk += 15;
    if (moodAvg != null && moodAvg < 5.5) risk += 20;
    return risk.clamp(0, 100);
  }

  static String _riskLabel(int score) {
    if (score < 35) return "Low";
    if (score < 65) return "Medium";
    return "High";
  }

  static List<HealthRiskMetric> _healthMetrics({
    required DashboardMetrics metrics,
    required int habitPct,
    required double? moodAvg,
    required int exercisePct,
    required int sleepPct,
  }) {
    return [
      HealthRiskMetric(
        icon: Icons.nightlight_round,
        label: "Sleep habits",
        status: _statusFromPercent(sleepPct),
        isWarning: sleepPct < 50,
      ),
      HealthRiskMetric(
        icon: Icons.smartphone_outlined,
        label: "Screen time",
        status: metrics.hasUsageData
            ? (metrics.screenDiffMinutes > 30 ? "High" : "Balanced")
            : "No data",
        isWarning: metrics.screenDiffMinutes > 30 || !metrics.hasUsageData,
      ),
      HealthRiskMetric(
        icon: Icons.favorite_border,
        label: "Exercise habits",
        status: _statusFromPercent(exercisePct),
        isWarning: exercisePct < 40,
      ),
      HealthRiskMetric(
        icon: Icons.psychology_outlined,
        label: "Mood",
        status: moodAvg == null ? "Not logged" : _statusFromScore(moodAvg),
        isWarning: moodAvg != null && moodAvg < 6,
      ),
    ];
  }

  static String _statusFromPercent(int pct) {
    if (pct >= 70) return "Good";
    if (pct >= 40) return "Fair";
    return "Needs work";
  }

  static String _statusFromScore(double score) {
    if (score >= 7.5) return "Good";
    if (score >= 5.5) return "Fair";
    return "Low";
  }

  static int _physicalWellness(int exercise, int water, int sleep, int overallHabits) {
    final values = [exercise, water, sleep, overallHabits].where((v) => v > 0).toList();
    if (values.isEmpty) return 0;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  static int _mentalWellness(double? mood, int focus) {
    final moodScore = mood != null ? (mood * 10).round() : focus;
    return ((moodScore + focus) / 2).round().clamp(0, 100);
  }

  static List<SmartRecommendation> _ruleRecommendations({
    required DashboardMetrics metrics,
    required int habitPct,
    required double? moodAvg,
    required int exercisePct,
    required int waterPct,
  }) {
    final list = <SmartRecommendation>[];

    if (!metrics.hasUsageData) {
      list.add(
        const SmartRecommendation(
          title: "Enable usage tracking",
          description:
              "Grant usage access so screen time, focus, and trends can be calculated.",
          hint: "Open Settings from the onboarding flow",
          icon: Icons.settings_outlined,
          iconColor: Color(0xFF2563EB),
          background: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
          priority: RecommendationPriority.high,
        ),
      );
      return list;
    }

    if (metrics.screenDiffMinutes > 30) {
      list.add(
        SmartRecommendation(
          title: "Screen time above average",
          description:
              "Today is ${formatMinutes(metrics.screenDiffMinutes)} above your usual daily usage.",
          hint: "Try a 30-minute phone-free block",
          icon: Icons.smartphone_outlined,
          iconColor: const Color(0xFFEA580C),
          background: const Color(0xFFFFFBEB),
          border: const Color(0xFFFDE68A),
          priority: RecommendationPriority.high,
        ),
      );
    }

    if (waterPct >= 85) {
      list.add(
        const SmartRecommendation(
          title: "Strong hydration week",
          description: "Water habit check-ins are consistent this week.",
          hint: "Keep it up!",
          icon: Icons.check_circle_outline,
          iconColor: Color(0xFF16A34A),
          background: Color(0xFFECFDF5),
          border: Color(0xFFBBF7D0),
        ),
      );
    } else if (waterPct < 50) {
      list.add(
        const SmartRecommendation(
          title: "Log water more often",
          description: "Your water habit completion is below half this week.",
          hint: "Use quick log on the Habit tab",
          icon: Icons.water_drop_outlined,
          iconColor: Color(0xFF2563EB),
          background: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
        ),
      );
    }

    if (habitPct < 45) {
      list.add(
        SmartRecommendation(
          title: "Build habit momentum",
          description: "Weekly habit completion is $habitPct%. Small daily check-ins add up.",
          hint: "Aim for one habit at the same time each day",
          icon: Icons.check_circle_outline,
          iconColor: Color(0xFF7C3AED),
          background: Color(0xFFF5F3FF),
          border: Color(0xFFDDD6FE),
          priority: RecommendationPriority.high,
        ),
      );
    }

    if (moodAvg != null && moodAvg < 6) {
      list.add(
        SmartRecommendation(
          title: "Mood below average",
          description:
              "Your mood average is ${moodAvg.toStringAsFixed(1)}/10 this week.",
          hint: "Log mood daily on the Habit tab",
          icon: Icons.psychology_outlined,
          iconColor: Color(0xFF7C3AED),
          background: Color(0xFFF3E8FF),
          border: Color(0xFFE8D5FF),
        ),
      );
    }

    if (metrics.focusScore < 50) {
      list.add(
        SmartRecommendation(
          title: "Reduce distracting apps",
          description: "Focus score is ${metrics.focusScore}/100 — social apps may be pulling attention.",
          hint: "Check Top apps on Apps tab",
          icon: Icons.phonelink_off_outlined,
          iconColor: Color(0xFFEA580C),
          background: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
        ),
      );
    }

    if (list.isEmpty) {
      list.add(
        SmartRecommendation(
          title: "Steady week overall",
          description: "Usage, habits, and mood look balanced. Maintain your current routine.",
          hint: "Keep logging on the Habit tab",
          icon: Icons.thumb_up_outlined,
          iconColor: Color(0xFF16A34A),
          background: Color(0xFFECFDF5),
          border: Color(0xFFBBF7D0),
        ),
      );
    }

    return list.take(4).toList();
  }

  static List<WeeklyTrendItem> _weeklyTrends({
    required DashboardMetrics metrics,
    required int habitPct,
    required double? moodAvg,
  }) {
    return [
      WeeklyTrendItem(
        label: "Screen time",
        changePercent: metrics.weekOverWeekScreenPercent ?? 0,
      ),
      WeeklyTrendItem(
        label: "Habit completion",
        changePercent: habitPct - 50,
      ),
      WeeklyTrendItem(
        label: "Focus score",
        changePercent: metrics.focusScore - 50,
      ),
      WeeklyTrendItem(
        label: "Mood",
        changePercent: moodAvg != null ? ((moodAvg - 7) * 12).round() : 0,
      ),
    ];
  }

  static List<AiInsightTip> tipsFromLines(List<String> lines) {
    const icons = [
      Icons.psychology_outlined,
      Icons.auto_awesome,
      Icons.lightbulb_outline,
    ];
    final tips = <AiInsightTip>[];
    for (var i = 0; i < lines.length && i < 3; i++) {
      final parts = lines[i].split("|");
      final title = parts.first.trim();
      final desc = parts.length > 1 ? parts.sublist(1).join("|").trim() : lines[i];
      tips.add(
        AiInsightTip(
          title: title.length > 40 ? "${title.substring(0, 40)}…" : title,
          description: desc,
          hint: "Personalized by AI",
          icon: icons[i % icons.length],
          iconColor: const Color(0xFF7C3AED),
          background: const Color(0xFFF3E8FF),
        ),
      );
    }
    return tips;
  }

  static List<AiInsightTip> fallbackAiTips(DashboardMetrics metrics, int habitPct) {
    return [
      AiInsightTip(
        title: "Peak usage window",
        description: metrics.peakHourLabel ??
            "Track hourly usage on the Apps tab to find busy periods.",
        hint: "Calculated insight",
        icon: Icons.schedule,
        iconColor: const Color(0xFF7C3AED),
        background: const Color(0xFFEFF6FF),
      ),
      AiInsightTip(
        title: "Habit focus",
        description: habitPct >= 60
            ? "Habit completion is strong — keep the same routine next week."
            : "Pick one habit to complete every day this week.",
        hint: "Calculated insight",
        icon: Icons.check_circle_outline,
        iconColor: const Color(0xFF7C3AED),
        background: const Color(0xFFF3E8FF),
      ),
    ];
  }
}
