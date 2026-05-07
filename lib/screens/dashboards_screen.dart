import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:life_pattern_tracker/widgets/summary_card.dart";

class DashboardsScreen extends ConsumerWidget {
  const DashboardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);
    final notifier = ref.read(usageProvider.notifier);
    final today = state.today;
    final avg = notifier.averageDailyMinutes();
    final productivity = notifier.productivityScore();
    final focus = notifier.focusScore();
    final topApp = today?.appUsages.isNotEmpty == true ? today!.appUsages.first : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SummaryCard(
          title: "Daily Overview",
          value: formatMinutes(today?.totalScreenTime ?? 0),
          subtitle: "Compared to average ${formatMinutes(avg)}",
          icon: Icons.dashboard_customize_outlined,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: "Productivity",
                value: "$productivity/100",
                subtitle: "AI readiness score",
                icon: Icons.psychology_alt_outlined,
                color: Colors.teal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: "Focus",
                value: "$focus/100",
                subtitle: "Distraction control",
                icon: Icons.track_changes_outlined,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: const Text("Most Used App"),
            subtitle: Text(topApp?.appName ?? "No app data yet"),
            trailing: Text(formatMinutes(topApp?.usageTime ?? 0)),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Dashboard Notes", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  _notes(today?.totalScreenTime ?? 0, avg),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _notes(int today, int avg) {
    if (today == 0) return "No usage data detected yet. Refresh after granting usage permission.";
    if (today > avg + 60) return "Usage is well above your baseline today. Consider a short screen break every hour.";
    if (today < avg - 30) return "Great job. You are below your typical screen-time baseline today.";
    return "Usage is close to your normal pattern. Keep current focus habits steady.";
  }
}
