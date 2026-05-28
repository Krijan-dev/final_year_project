import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/dashboard_provider.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:life_pattern_tracker/widgets/account_avatar_button.dart";

const Color _kGreen = Color(0xFF34D399);
const Color _kGreenDark = Color(0xFF22C55E);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (dash.syncing) const LinearProgressIndicator(minHeight: 2),
          if (dash.usageError != null) ...[
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  dash.usageError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          _DashboardHeader(metrics: m),
          const SizedBox(height: 16),
          _TodayOverviewCard(metrics: m),
          const SizedBox(height: 16),
          _WellnessStyleScores(metrics: m),
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.speed_outlined,
            iconColor: Color(0xFF0D9488),
            title: "Today's metrics",
            badge: "Live",
          ),
          const SizedBox(height: 12),
          _TodayMetricsGrid(metrics: m),
          if (m.ruleInsights.isNotEmpty) ...[
            const SizedBox(height: 20),
            const _SectionTitle(
              icon: Icons.lightbulb_outline,
              iconColor: Color(0xFFF59E0B),
              title: "Quick insights",
              badge: "Calculated",
            ),
            const SizedBox(height: 12),
            ...m.ruleInsights.map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InsightLineCard(text: text),
              ),
            ),
          ],
          if (m.hasUsageData) ...[
            const SizedBox(height: 8),
            const Card(
              child: ListTile(
                leading: Icon(Icons.smartphone_outlined, color: Color(0xFF2563EB)),
                title: Text("Full screen time breakdown"),
                subtitle: Text("Charts, categories, and all apps on the Time tab."),
                trailing: Icon(Icons.chevron_right),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Dashboard",
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const AccountAvatarButton(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          metrics.hasUsageData
              ? metrics.coachSummaryFallback
              : "Grant usage access under More → Account, or open Time for charts.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TodayOverviewCard extends StatelessWidget {
  const _TodayOverviewCard({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenLabel = metrics.hasUsageData
        ? formatMinutes(metrics.screenMinutes)
        : "No data yet";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen, _kGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.dashboard_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's overview",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      screenLabel,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metrics.screenTimeSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (metrics.hasUsageData)
                Text(
                  "${(metrics.screenProgress * 100).round()}%",
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.28,
            children: [
              _HeroMetricTile(
                icon: Icons.track_changes_outlined,
                label: "Productivity",
                value: metrics.hasUsageData ? "${metrics.productivityScore}" : "—",
                progress: metrics.hasUsageData ? metrics.productivityScore / 100 : 0,
              ),
              _HeroMetricTile(
                icon: Icons.center_focus_strong,
                label: "Focus",
                value: metrics.hasUsageData ? "${metrics.focusScore}" : "—",
                progress: metrics.hasUsageData ? metrics.focusScore / 100 : 0,
              ),
              _HeroMetricTile(
                icon: Icons.calendar_view_week_rounded,
                label: "Habits",
                value: "${metrics.habitCompletionPercent}%",
                progress: metrics.habitCompletionPercent / 100,
              ),
              _HeroMetricTile(
                icon: Icons.local_fire_department_outlined,
                label: "Best streak",
                value: "${metrics.bestStreakDays}d",
                progress: (metrics.bestStreakDays / 30).clamp(0, 1).toDouble(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessStyleScores extends StatelessWidget {
  const _WellnessStyleScores({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite_border, color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 8),
            Text(
              "Wellness scores",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _ScoreTile(
                  score: metrics.hasUsageData ? metrics.productivityScore : 0,
                  label: "Productivity",
                  background: const Color(0xFFECFDF5),
                  foreground: _kGreenDark,
                  track: _kGreenDark.withValues(alpha: 0.18),
                  showDash: !metrics.hasUsageData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScoreTile(
                  score: metrics.hasUsageData ? metrics.focusScore : 0,
                  label: "Focus",
                  background: const Color(0xFFF5F3FF),
                  foreground: const Color(0xFF7C3AED),
                  track: const Color(0xFF7C3AED).withValues(alpha: 0.18),
                  showDash: !metrics.hasUsageData,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Column(
            children: [
              Text(
                "${metrics.habitCompletionPercent}",
                style: theme.textTheme.displayMedium?.copyWith(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Weekly habit completion %",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metrics.habitSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.score,
    required this.label,
    required this.background,
    required this.foreground,
    required this.track,
    this.showDash = false,
  });

  final int score;
  final String label;
  final Color background;
  final Color foreground;
  final Color track;
  final bool showDash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            showDash ? "—" : "$score",
            style: theme.textTheme.headlineLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: showDash ? 0 : (score / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: track.withValues(alpha: 0.5),
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayMetricsGrid extends StatelessWidget {
  const _TodayMetricsGrid({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricDetailCard(
              title: "Screen time",
              value: metrics.hasUsageData ? formatMinutes(metrics.screenMinutes) : "—",
              subtitle: metrics.screenTimeSubtitle,
              icon: Icons.hourglass_top_rounded,
              color: Colors.red,
              progress: metrics.screenProgress,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricDetailCard(
              title: "Avg daily",
              value: metrics.averageMinutes > 0 ? formatMinutes(metrics.averageMinutes) : "—",
              subtitle: metrics.averageMinutes > 0
                  ? "Across ${metrics.hasUsageData ? "synced" : "stored"} days"
                  : "Sync more days for average",
              icon: Icons.calendar_today_outlined,
              color: Colors.blue,
              progress: null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricDetailCard extends StatelessWidget {
  const _MetricDetailCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.progress,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final track = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress!.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: track,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InsightLineCard extends StatelessWidget {
  const _InsightLineCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: Color(0xFFD97706), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        if (badge != null)
          Text(
            badge!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
