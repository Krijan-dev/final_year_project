import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/insight_models.dart";

class InsightsState {
  const InsightsState({
    required this.healthRiskLabel,
    required this.healthRiskScore,
    required this.healthMetrics,
    required this.overallWellnessScore,
    required this.wellnessScores,
    required this.recommendations,
    required this.aiTips,
    required this.weeklyTrends,
  });

  final String healthRiskLabel;
  final int healthRiskScore;
  final List<HealthRiskMetric> healthMetrics;
  final int overallWellnessScore;
  final List<WellnessScoreItem> wellnessScores;
  final List<SmartRecommendation> recommendations;
  final List<AiInsightTip> aiTips;
  final List<WeeklyTrendItem> weeklyTrends;
}

class InsightsNotifier extends StateNotifier<InsightsState> {
  InsightsNotifier() : super(_sample);

  static final InsightsState _sample = InsightsState(
    healthRiskLabel: "Low",
    healthRiskScore: 25,
    healthMetrics: const [
      HealthRiskMetric(icon: Icons.nightlight_round, label: "Sleep Quality", status: "Good"),
      HealthRiskMetric(
        icon: Icons.smartphone_outlined,
        label: "Screen Time",
        status: "Warning",
        isWarning: true,
      ),
      HealthRiskMetric(icon: Icons.favorite_border, label: "Physical Activity", status: "Good"),
      HealthRiskMetric(icon: Icons.psychology_outlined, label: "Mental Health", status: "Good"),
    ],
    overallWellnessScore: 75,
    wellnessScores: const [
      WellnessScoreItem(
        label: "Physical",
        score: 82,
        background: Color(0xFFDCFCE7),
        foreground: Color(0xFF16A34A),
      ),
      WellnessScoreItem(
        label: "Mental",
        score: 78,
        background: Color(0xFFDBEAFE),
        foreground: Color(0xFF2563EB),
      ),
    ],
    recommendations: const [
      SmartRecommendation(
        title: "Improve Sleep Schedule",
        description:
            "Your sleep pattern shows inconsistency. Try going to bed at the same time every night.",
        hint: "Could improve productivity by 15%",
        icon: Icons.nightlight_round,
        iconColor: Color(0xFF2563EB),
        background: Color(0xFFEFF6FF),
        border: Color(0xFFBFDBFE),
        priority: RecommendationPriority.high,
      ),
      SmartRecommendation(
        title: "Great Water Intake!",
        description: "You've maintained perfect hydration for 7 days straight.",
        hint: "Keep it up!",
        icon: Icons.check_circle_outline,
        iconColor: Color(0xFF16A34A),
        background: Color(0xFFECFDF5),
        border: Color(0xFFBBF7D0),
      ),
      SmartRecommendation(
        title: "Screen Time Increasing",
        description: "Your daily screen time has increased by 20% this week.",
        hint: "Consider setting app time limits",
        icon: Icons.smartphone_outlined,
        iconColor: Color(0xFFEA580C),
        background: Color(0xFFFFFBEB),
        border: Color(0xFFFDE68A),
        priority: RecommendationPriority.high,
      ),
      SmartRecommendation(
        title: "Optimize Break Times",
        description: "Taking regular breaks at 3 PM could boost your afternoon focus.",
        hint: "Potential 10% focus improvement",
        icon: Icons.coffee_outlined,
        iconColor: Color(0xFF7C3AED),
        background: Color(0xFFF5F3FF),
        border: Color(0xFFDDD6FE),
      ),
    ],
    aiTips: const [
      AiInsightTip(
        title: "Optimize Break Times",
        description: "Taking regular breaks at 3 PM could boost your afternoon focus.",
        hint: "Potential 10% focus improvement",
        icon: Icons.coffee_outlined,
        iconColor: Color(0xFF7C3AED),
        background: Color(0xFFF3E8FF),
      ),
      AiInsightTip(
        title: "Morning Routine Pattern",
        description: "Your productivity peaks at 11 AM. Schedule important tasks then.",
        hint: "Maximize your peak performance",
        icon: Icons.psychology_outlined,
        iconColor: Color(0xFF7C3AED),
        background: Color(0xFFEFF6FF),
      ),
    ],
    weeklyTrends: const [
      WeeklyTrendItem(label: "Productivity", changePercent: 12),
      WeeklyTrendItem(label: "Sleep Quality", changePercent: 0),
      WeeklyTrendItem(label: "Screen Time", changePercent: -8),
      WeeklyTrendItem(label: "Exercise", changePercent: 15),
    ],
  );

  Future<void> refresh() async {
    state = _sample;
  }
}

final insightsProvider = StateNotifierProvider<InsightsNotifier, InsightsState>((ref) {
  return InsightsNotifier();
});
