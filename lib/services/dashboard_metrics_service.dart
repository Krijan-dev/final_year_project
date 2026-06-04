import "dart:math";

import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

/// Rule-based dashboard numbers derived from usage + habit tracker (no AI).
class DashboardMetrics {
  const DashboardMetrics({
    required this.screenMinutes,
    required this.averageMinutes,
    required this.screenDiffMinutes,
    required this.screenProgress,
    required this.productivityScore,
    required this.focusScore,
    required this.habitCompletionPercent,
    required this.bestStreakDays,
    required this.topApps,
    required this.hourlyMinutes,
    required this.chartMaxY,
    required this.screenTimeSubtitle,
    required this.productivitySubtitle,
    required this.focusSubtitle,
    required this.habitSubtitle,
    required this.streakSubtitle,
    required this.ruleInsights,
    required this.coachSummaryFallback,
    this.moodAverage,
    this.weekOverWeekScreenPercent,
    this.peakHourLabel,
    this.hasUsageData = false,
  });

  final int screenMinutes;
  final int averageMinutes;
  final int screenDiffMinutes;
  final double screenProgress;
  final int productivityScore;
  final int focusScore;
  final int habitCompletionPercent;
  final int bestStreakDays;
  final List<AppUsageModel> topApps;
  final List<int> hourlyMinutes;
  final int chartMaxY;
  final String screenTimeSubtitle;
  final String productivitySubtitle;
  final String focusSubtitle;
  final String habitSubtitle;
  final String streakSubtitle;
  final List<String> ruleInsights;
  final String coachSummaryFallback;
  final double? moodAverage;
  final int? weekOverWeekScreenPercent;
  final String? peakHourLabel;
  final bool hasUsageData;
}

abstract final class DashboardMetricsService {
  static const int dailyScreenTimeGoalMinutes = 480;

  static const HabitTrackerState _emptyHabits = HabitTrackerState(
    ready: true,
    weekKey: "",
    habits: [],
    moodDays: [],
    logs: [],
  );

  /// Scores from today's usage only (for chat / other tabs without habit context).
  static int focusScoreForToday(DailyUsageModel? today) =>
      build(today: today, history: const [], habits: _emptyHabits).focusScore;

  static int productivityScoreForToday(DailyUsageModel? today) =>
      build(today: today, history: const [], habits: _emptyHabits).productivityScore;

  static DashboardMetrics build({
    DailyUsageModel? today,
    required List<DailyUsageModel> history,
    required HabitTrackerState habits,
  }) {
    final screenMinutes = today?.totalScreenTime ?? 0;
    final hasUsage = today != null && screenMinutes > 0;
    final averageMinutes = _averageMinutes(history);
    final screenDiff = screenMinutes - averageMinutes;

    final apps = today?.appUsages ?? const <AppUsageModel>[];
    final socialMins = _minutesInCategories(
      apps,
      const ["social"],
      nameHints: const ["instagram", "facebook", "tiktok", "snapchat", "twitter", "x "],
    );
    final productiveMins = _minutesInCategories(
      apps,
      const ["productivity", "education"],
      nameHints: const ["docs", "drive", "slack", "notion", "office", "word"],
    );
    final gameMins = _minutesInCategories(apps, const ["game"]);

    final focusScore = _focusScore(screenMinutes, socialMins);
    final productivityScore = _productivityScore(
      screenMinutes: screenMinutes,
      productiveMins: productiveMins,
      socialMins: socialMins,
      gameMins: gameMins,
    );

    final hourly = today?.hourlyUsageMinutes ?? List<int>.filled(24, 0);
    final chartMax = max(60, hourly.fold<int>(0, (a, b) => a > b ? a : b));
    final peakHour = _peakHourLabel(hourly);

    final habitPct = habits.ready ? habits.weeklyProgressPercent : 0;
    final streak = habits.ready ? habits.bestStreakDays : 0;
    final moodAvg = habits.ready && habits.averageMood > 0 ? habits.averageMood : null;

    final weekTrend = _weekOverWeekScreenChange(history);
    final ruleInsights = _ruleInsights(
      screenMinutes: screenMinutes,
      averageMinutes: averageMinutes,
      screenDiff: screenDiff,
      focusScore: focusScore,
      productivityScore: productivityScore,
      habitPct: habitPct,
      moodAvg: moodAvg,
      peakHour: peakHour,
      socialMins: socialMins,
      weekTrend: weekTrend,
      hasUsage: hasUsage,
    );

    return DashboardMetrics(
      hasUsageData: hasUsage,
      screenMinutes: screenMinutes,
      averageMinutes: averageMinutes,
      screenDiffMinutes: screenDiff,
      screenProgress: dailyScreenTimeGoalMinutes <= 0
          ? 0
          : (screenMinutes / dailyScreenTimeGoalMinutes).clamp(0.0, 1.0),
      productivityScore: productivityScore,
      focusScore: focusScore,
      habitCompletionPercent: habitPct,
      bestStreakDays: streak,
      topApps: apps.take(5).toList(),
      hourlyMinutes: hourly,
      chartMaxY: chartMax,
      screenTimeSubtitle: _screenSubtitle(today, screenDiff, averageMinutes),
      productivitySubtitle: _productivitySubtitle(productivityScore, productiveMins),
      focusSubtitle: _focusSubtitle(focusScore, socialMins),
      habitSubtitle: habitPct > 0 ? "$habitPct% of weekly check-ins" : "Log habits on the Habit tab",
      streakSubtitle: streak > 0 ? "$streak day current streak" : "Build streaks with daily habits",
      ruleInsights: ruleInsights,
      coachSummaryFallback: _coachFallback(
        screenDiff: screenDiff,
        focusScore: focusScore,
        habitPct: habitPct,
        moodAvg: moodAvg,
      ),
      moodAverage: moodAvg,
      weekOverWeekScreenPercent: weekTrend,
      peakHourLabel: peakHour,
    );
  }

  static int _averageMinutes(List<DailyUsageModel> history) {
    if (history.isEmpty) return 0;
    final total = history.fold<int>(0, (s, d) => s + d.totalScreenTime);
    return (total / history.length).round();
  }

  static int _minutesInCategories(
    List<AppUsageModel> apps,
    List<String> categories, {
    List<String> nameHints = const [],
  }) {
    return apps.fold<int>(0, (sum, app) {
      final cat = app.category.toLowerCase();
      final name = app.appName.toLowerCase();
      final catMatch = categories.any((c) => cat.contains(c));
      final nameMatch = nameHints.any((h) => name.contains(h.trim()));
      if (catMatch || nameMatch) return sum + app.usageTime;
      return sum;
    });
  }

  static int _focusScore(int screenMinutes, int socialMins) {
    if (screenMinutes <= 0) return 0;
    final socialShare = (socialMins / screenMinutes).clamp(0.0, 1.0);
    final score = 100 - (socialShare * 70).round() - min(25, screenMinutes ~/ 30);
    return score.clamp(0, 100).toInt();
  }

  static int _productivityScore({
    required int screenMinutes,
    required int productiveMins,
    required int socialMins,
    required int gameMins,
  }) {
    if (screenMinutes <= 0) return 0;
    final productiveShare = productiveMins / screenMinutes;
    final distractionShare = (socialMins + gameMins) / screenMinutes;
    final raw = 55 + (productiveShare * 45).round() - (distractionShare * 40).round();
    final overusePenalty = max(0, (screenMinutes - dailyScreenTimeGoalMinutes) ~/ 12);
    return (raw - overusePenalty).clamp(0, 100);
  }

  static String _screenSubtitle(
    DailyUsageModel? today,
    int diff,
    int average,
  ) {
    if (today == null) return "Grant usage access and refresh";
    final phoneSource = today.screenTimeSource?.trim();
    if (phoneSource != null && phoneSource.isNotEmpty) {
      return phoneSource;
    }
    if (average <= 0) {
      return "${formatDateShort(today.date)} · goal ${formatMinutes(dailyScreenTimeGoalMinutes)}";
    }
    if (diff == 0) return "${formatDateShort(today.date)} · in line with your average";
    final dir = diff > 0 ? "above" : "below";
    return "${formatDateShort(today.date)} · ${formatMinutes(diff.abs())} $dir avg";
  }

  static String _productivitySubtitle(int score, int productiveMins) {
    if (productiveMins > 0) {
      return "$score/100 · ${formatMinutes(productiveMins)} productive apps";
    }
    return "$score/100 · based on app categories";
  }

  static String _focusSubtitle(int score, int socialMins) {
    if (socialMins > 0) {
      return "$score/100 · ${formatMinutes(socialMins)} on social";
    }
    return "$score/100 · lower social share = higher focus";
  }

  static String? _peakHourLabel(List<int> hourly) {
    var best = 0;
    var bestHour = 0;
    for (var h = 0; h < hourly.length; h++) {
      if (hourly[h] > best) {
        best = hourly[h];
        bestHour = h;
      }
    }
    if (best < 5) return null;
    final display = bestHour == 0
        ? 12
        : bestHour > 12
            ? bestHour - 12
            : bestHour;
    final period = bestHour >= 12 ? "PM" : "AM";
    return "Busiest around $display:00 $period (${formatMinutes(best)})";
  }

  static int? _weekOverWeekScreenChange(List<DailyUsageModel> history) {
    if (history.length < 8) return null;
    final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.sublist(sorted.length - 7);
    final prior = sorted.sublist(max(0, sorted.length - 14), sorted.length - 7);
    if (prior.isEmpty) return null;
    final recentAvg = recent.fold<int>(0, (s, d) => s + d.totalScreenTime) / recent.length;
    final priorAvg = prior.fold<int>(0, (s, d) => s + d.totalScreenTime) / prior.length;
    if (priorAvg <= 0) return null;
    return (((recentAvg - priorAvg) / priorAvg) * 100).round();
  }

  static List<String> _ruleInsights({
    required int screenMinutes,
    required int averageMinutes,
    required int screenDiff,
    required int focusScore,
    required int productivityScore,
    required int habitPct,
    required double? moodAvg,
    required String? peakHour,
    required int socialMins,
    required int? weekTrend,
    required bool hasUsage,
  }) {
    final lines = <String>[];
    if (!hasUsage) {
      lines.add("Enable usage access in Settings to see screen time and scores.");
      return lines;
    }
    if (weekTrend != null) {
      final dir = weekTrend > 0 ? "up" : weekTrend < 0 ? "down" : "flat";
      lines.add("Screen time is $dir ${weekTrend.abs()}% vs last week (7-day average).");
    } else if (averageMinutes > 0) {
      if (screenDiff > 15) {
        lines.add("Today is ${formatMinutes(screenDiff)} above your usual daily average.");
      } else if (screenDiff < -15) {
        lines.add("Today is ${formatMinutes(-screenDiff)} below your usual daily average.");
      } else {
        lines.add("Today's screen time is close to your historical average.");
      }
    }
    if (peakHour != null) lines.add(peakHour);
    if (socialMins >= 60) {
      lines.add("Social apps account for ${formatMinutes(socialMins)} — consider a focus block.");
    }
    if (habitPct >= 70) {
      lines.add("Strong habit week at $habitPct% completion.");
    } else if (habitPct > 0 && habitPct < 40) {
      lines.add("Habit completion is $habitPct% — small daily check-ins help.");
    }
    if (moodAvg != null && moodAvg < 6) {
      lines.add("Mood average is ${moodAvg.toStringAsFixed(1)}/10 — logging on the Habit tab can help spot patterns.");
    }
    if (productivityScore < 50 && focusScore < 50) {
      lines.add("Productivity and focus scores are both under 50 — trim distracting apps first.");
    }
    if (lines.isEmpty) {
      lines.add("Scores look balanced today. Keep steady habits and screen-time goals.");
    }
    return lines.take(4).toList();
  }

  static String _coachFallback({
    required int screenDiff,
    required int focusScore,
    required int habitPct,
    required double? moodAvg,
  }) {
    final parts = <String>[];
    if (screenDiff > 20) {
      parts.add("Screen time is running higher than usual — try a 25-minute break from your top app.");
    } else if (screenDiff < -20) {
      parts.add("You're under your usual screen time — good room to focus on priority tasks.");
    } else {
      parts.add("Usage is near your normal pattern today.");
    }
    if (focusScore < 55) {
      parts.add("Focus score is low; mute social notifications for one work block.");
    } else if (focusScore >= 75) {
      parts.add("Focus looks solid — schedule deep work while it lasts.");
    }
    if (habitPct > 0) {
      parts.add("Habit completion is at $habitPct% this week.");
    }
    if (moodAvg != null) {
      parts.add("Average mood is ${moodAvg.toStringAsFixed(1)}/10.");
    }
    return parts.join(" ");
  }
}
