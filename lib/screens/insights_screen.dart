import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:life_pattern_tracker/widgets/summary_card.dart";
import "package:life_pattern_tracker/widgets/usage_bar_chart.dart";

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);
    final notifier = ref.read(usageProvider.notifier);
    final today = state.today;
    final history = state.history;
    final week = history.length <= 7 ? history : history.sublist(history.length - 7);
    final weekValues = week.map((e) => e.totalScreenTime).toList();
    final peakLabel = _peakUsageLabel(today);
    final avg = notifier.averageDailyMinutes();
    final grouped = _categoryBreakdown(today);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SummaryCard(
          title: "Average Daily Usage",
          value: formatMinutes(avg),
          subtitle: "Based on ${history.length} day(s)",
          icon: Icons.analytics_outlined,
        ),
        const SizedBox(height: 12),
        SummaryCard(
          title: "Peak Usage Period",
          value: peakLabel,
          subtitle: "Detected from today's hour-by-hour pattern",
          icon: Icons.schedule,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("7-Day Trend", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: UsageBarChart(
                    values: weekValues.isEmpty ? [0] : weekValues,
                    maxY: weekValues.isEmpty ? 0 : weekValues.reduce((a, b) => a > b ? a : b),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Category Breakdown", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (grouped.isEmpty)
                  const Text("No category insights yet.")
                else
                  ...grouped.entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [Text(entry.key), Text(formatMinutes(entry.value))],
                        ),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _behaviorSummary(today, avg),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ],
    );
  }

  String _peakUsageLabel(DailyUsageModel? model) {
    if (model == null || model.hourlyUsageMinutes.every((e) => e == 0)) return "Not enough data";
    final maxMinute = model.hourlyUsageMinutes.reduce((a, b) => a > b ? a : b);
    final peakHour = model.hourlyUsageMinutes.indexOf(maxMinute);
    if (peakHour < 12) return "Morning";
    if (peakHour < 18) return "Afternoon";
    return "Night";
    }

  Map<String, int> _categoryBreakdown(DailyUsageModel? model) {
    if (model == null) return {};
    final map = <String, int>{};
    for (final app in model.appUsages) {
      final key = app.category.isEmpty ? "other" : app.category;
      map[key] = (map[key] ?? 0) + app.usageTime;
    }
    return map;
  }

  String _behaviorSummary(DailyUsageModel? today, int avg) {
    if (today == null) return "Grant permission and refresh to start building your behavior profile.";
    final diff = today.totalScreenTime - avg;
    final direction = diff > 0 ? "higher" : "lower";
    final delta = formatMinutes(diff.abs());
    return "Today's usage is $delta $direction than your average. "
        "Peak attention drift appears in ${_peakUsageLabel(today).toLowerCase()} hours. "
        "Try setting a short focus block before your peak usage window.";
  }
}
