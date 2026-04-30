import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:life_pattern_tracker/widgets/summary_card.dart";
import "package:life_pattern_tracker/widgets/usage_bar_chart.dart";

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageState = ref.watch(usageProvider);
    final notifier = ref.read(usageProvider.notifier);
    final today = usageState.today;

    return RefreshIndicator(
      onRefresh: notifier.refreshToday,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          SummaryCard(
            title: "Today Screen Time",
            value: formatMinutes(today?.totalScreenTime ?? 0),
            subtitle: today == null ? "No data yet" : formatDateShort(today.date),
            icon: Icons.hourglass_top_rounded,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: "Productivity",
                  value: "${notifier.productivityScore()}",
                  subtitle: "out of 100",
                  icon: Icons.track_changes_outlined,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: "Focus",
                  value: "${notifier.focusScore()}",
                  subtitle: "out of 100",
                  icon: Icons.center_focus_strong,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Top 5 apps", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...(today?.appUsages.take(5).map(
                        (app) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  app.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(formatMinutes(app.usageTime)),
                            ],
                          ),
                        ),
                      ) ??
                      const [Text("No app usage data available.")]),
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
                  Text("Hourly Usage Trend", style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: UsageBarChart(
                      values: today?.hourlyUsageMinutes ?? List<int>.filled(24, 0),
                      maxY: (today?.hourlyUsageMinutes ?? [0]).fold<int>(0, (a, b) => a > b ? a : b),
                      hourly: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
