import "package:flutter/material.dart";

class HealthRiskMetric {
  const HealthRiskMetric({
    required this.icon,
    required this.label,
    required this.status,
    this.isWarning = false,
  });

  final IconData icon;
  final String label;
  final String status;
  final bool isWarning;
}

class WellnessScoreItem {
  const WellnessScoreItem({
    required this.label,
    required this.score,
    required this.background,
    required this.foreground,
  });

  final String label;
  final int score;
  final Color background;
  final Color foreground;
}

enum RecommendationPriority { none, high }

class SmartRecommendation {
  const SmartRecommendation({
    required this.title,
    required this.description,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.border,
    this.priority = RecommendationPriority.none,
  });

  final String title;
  final String description;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color border;
  final RecommendationPriority priority;
}

class AiInsightTip {
  const AiInsightTip({
    required this.title,
    required this.description,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.background,
  });

  final String title;
  final String description;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final Color background;
}

class WeeklyTrendItem {
  const WeeklyTrendItem({
    required this.label,
    required this.changePercent,
  });

  final String label;
  final int changePercent;

  bool get isPositive => changePercent > 0;
  bool get isNegative => changePercent < 0;
}
