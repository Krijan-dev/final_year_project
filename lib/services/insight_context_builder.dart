import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

/// Builds a single text block for Gemini prompts (Insights tab, chat, etc.).
abstract final class InsightContextBuilder {
  static String build({
    required DashboardMetrics metrics,
    required HabitTrackerState habits,
  }) {
    final habitPct = habits.ready ? habits.weeklyProgressPercent : 0;
    final moodLine = metrics.moodAverage != null
        ? "Average mood this week: ${metrics.moodAverage!.toStringAsFixed(1)}/10."
        : "No mood logged this week yet.";

    final exercisePct = _habitPct(habits, "exercise");
    final waterPct = _habitPct(habits, "water");
    final sleepPct = _habitPct(habits, "sleep");
    final moodHabitPct = _habitPct(habits, "mood");

    final topApps = _formatTopApps(metrics.topApps, limit: 8);
    final categories = _formatCategories(metrics.topApps);
    final weekTrend = metrics.weekOverWeekScreenPercent;
    final weekTrendLine = weekTrend == null
        ? "Week-over-week screen time: not enough history."
        : "Week-over-week screen time change: ${weekTrend > 0 ? '+' : ''}$weekTrend% vs prior week average.";

    final peak = metrics.peakHourLabel ?? "Peak hour: unknown (need usage data).";
    final diff = metrics.screenDiffMinutes;
    final diffLine = metrics.averageMinutes > 0
        ? "Today vs your stored daily average: ${diff >= 0 ? '+' : ''}${formatMinutes(diff.abs())} ${diff >= 0 ? 'above' : 'below'} average."
        : "No average yet for comparison.";

    final ruleLines = metrics.ruleInsights.isEmpty
        ? "No rule insights."
        : metrics.ruleInsights.map((e) => "- $e").join("\n");

    final todayLogs = habits.ready ? habits.todayLogs.length : 0;
    final bestStreak = habits.ready ? habits.bestStreakDays : 0;

    return """
SCREEN TIME & USAGE
- Today total screen time: ${formatMinutes(metrics.screenMinutes)} (${metrics.hasUsageData ? 'has data' : 'no usage permission/data'})
- Daily goal reference: ${formatMinutes(DashboardMetricsService.dailyScreenTimeGoalMinutes)}
- 7-day stored average: ${formatMinutes(metrics.averageMinutes)}
- $diffLine
- $weekTrendLine
- $peak
- Focus score (0-100, higher = less social distraction): ${metrics.focusScore}
- Productivity score (0-100): ${metrics.productivityScore}
- Top apps today (name, minutes, category):
$topApps
- Time by category today: $categories

HABITS & MOOD (this week)
- Weekly habit completion: $habitPct%
- Best habit streak (days): $bestStreak
- Exercise habit completion: $exercisePct%
- Water habit completion: $waterPct%
- Sleep habit completion: $sleepPct%
- Mood check habit completion: $moodHabitPct%
- $moodLine
- Today's habit log sessions: $todayLogs

CALCULATED INSIGHTS (from app rules)
$ruleLines
""";
  }

  static int _habitPct(HabitTrackerState habits, String id) {
    if (!habits.ready) return 0;
    for (final h in habits.habits) {
      if (h.id == id) return h.percent;
    }
    return 0;
  }

  static String _formatTopApps(List<AppUsageModel> apps, {int limit = 8}) {
    if (apps.isEmpty) return "- (none)";
    final lines = <String>[];
    for (final a in apps.take(limit)) {
      lines.add("- ${a.appName}: ${formatMinutes(a.usageTime)} (${a.category})");
    }
    return lines.join("\n");
  }

  static String _formatCategories(List<AppUsageModel> apps) {
    if (apps.isEmpty) return "no app breakdown";
    var social = 0, productive = 0, game = 0, other = 0;
    for (final a in apps) {
      final c = a.category.toLowerCase();
      if (c.contains("social")) {
        social += a.usageTime;
      } else if (c.contains("productivity") || c.contains("education")) {
        productive += a.usageTime;
      } else if (c.contains("game")) {
        game += a.usageTime;
      } else {
        other += a.usageTime;
      }
    }
    return "social ${formatMinutes(social)}, productive ${formatMinutes(productive)}, "
        "games ${formatMinutes(game)}, other ${formatMinutes(other)}";
  }
}
