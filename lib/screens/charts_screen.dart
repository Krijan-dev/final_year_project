import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/widgets/usage_bar_chart.dart";

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);
    final today = state.today;
    final history = state.history;
    final week = history.length <= 7 ? history : history.sublist(history.length - 7);
    final weekValues = week.map((d) => d.totalScreenTime).toList();
    final hourly = today?.hourlyUsageMinutes ?? List<int>.filled(24, 0);
    final maxHourly = hourly.fold<int>(0, (a, b) => a > b ? a : b);
    final maxWeekly = weekValues.isEmpty ? 0 : weekValues.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hourly Chart", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: UsageBarChart(values: hourly, maxY: maxHourly, hourly: true),
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
                Text("7-Day Chart", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: UsageBarChart(
                    values: weekValues.isEmpty ? [0] : weekValues,
                    maxY: maxWeekly,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
