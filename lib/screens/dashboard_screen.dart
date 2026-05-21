import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/dashboard_provider.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:life_pattern_tracker/widgets/summary_card.dart";

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static Widget _metricRow({required List<Widget> children}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardProvider);
    final controller = ref.read(dashboardProvider.notifier);
    final m = dash.metrics;
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (dash.syncing) const LinearProgressIndicator(minHeight: 2),
          if (dash.usageError != null) ...[
            const SizedBox(height: 8),
            Text(
              dash.usageError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 4),
          SummaryCard(
            title: "Today Screen Time",
            value: m.hasUsageData ? formatMinutes(m.screenMinutes) : "—",
            subtitle: m.screenTimeSubtitle,
            icon: Icons.hourglass_top_rounded,
            color: Colors.red,
            progress: m.screenProgress,
            uniformHeight: true,
          ),
          const SizedBox(height: 12),
          _metricRow(
            children: [
              Expanded(
                child: SummaryCard(
                  title: "Productivity",
                  value: m.hasUsageData ? "${m.productivityScore}" : "—",
                  subtitle: m.productivitySubtitle,
                  icon: Icons.track_changes_outlined,
                  color: Colors.green,
                  progress: m.productivityScore / 100,
                  uniformHeight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: "Focus",
                  value: m.hasUsageData ? "${m.focusScore}" : "—",
                  subtitle: m.focusSubtitle,
                  icon: Icons.center_focus_strong,
                  color: Colors.deepPurple,
                  progress: m.focusScore / 100,
                  uniformHeight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metricRow(
            children: [
              Expanded(
                child: SummaryCard(
                  title: "Habit completion",
                  value: "${m.habitCompletionPercent}%",
                  subtitle: m.habitSubtitle,
                  icon: Icons.calendar_view_week_rounded,
                  color: Colors.teal,
                  progress: m.habitCompletionPercent / 100,
                  uniformHeight: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: "Best streak",
                  value: "${m.bestStreakDays}",
                  subtitle: m.streakSubtitle,
                  icon: Icons.local_fire_department_outlined,
                  color: Colors.deepOrange,
                  progress: (m.bestStreakDays / 30).clamp(0.0, 1.0),
                  uniformHeight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
