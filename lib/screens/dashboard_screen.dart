import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/dashboard_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/services/gemini_service.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:life_pattern_tracker/widgets/account_avatar_button.dart";
import "package:life_pattern_tracker/widgets/green_hero_metric_tile.dart";
import "package:life_pattern_tracker/widgets/usage_access_prompt.dart";

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dash = ref.watch(dashboardProvider);
    final usage = ref.watch(usageProvider);
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
          if (!usage.hasPermission) ...[
            const UsageAccessPromptCard(compact: true),
            const SizedBox(height: 16),
          ] else if (!m.hasUsageData) ...[
            const _FirstOpenStarterCard(),
            const SizedBox(height: 16),
          ],
          _TodayOverviewCard(metrics: m, hasUsagePermission: usage.hasPermission),
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
          _TodayMetricsGrid(metrics: m, hasUsagePermission: usage.hasPermission),
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

class _DashboardHeader extends StatefulWidget {
  const _DashboardHeader({required this.metrics});

  final DashboardMetrics metrics;

  @override
  State<_DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<_DashboardHeader> {
  late List<String> _suggestions;
  int _selectedSuggestionIndex = 0;
  bool _loadingAi = false;
  String? _lastMetricsSignature;

  @override
  void initState() {
    super.initState();
    _suggestions = _fallbackSuggestions(widget.metrics);
    _lastMetricsSignature = _metricsSignature(widget.metrics);
    _loadAiSuggestions();
  }

  @override
  void didUpdateWidget(covariant _DashboardHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _metricsSignature(widget.metrics);
    if (nextSignature == _lastMetricsSignature) return;
    _lastMetricsSignature = nextSignature;
    _suggestions = _fallbackSuggestions(widget.metrics);
    _selectedSuggestionIndex = 0;
    _loadAiSuggestions();
  }

  String _metricsSignature(DashboardMetrics m) {
    return "${m.screenMinutes}|${m.averageMinutes}|${m.focusScore}|${m.productivityScore}|${m.habitCompletionPercent}";
  }

  List<String> _fallbackSuggestions(DashboardMetrics m) {
    final fallback = <String>[
      if (m.screenMinutes > m.averageMinutes)
        "Take a 20-minute no-phone walk to reduce stress and improve recovery.",
      if (m.screenMinutes <= m.averageMinutes)
        "Keep your rhythm with one calm focus block and a short stretch break.",
      if (m.habitCompletionPercent < 60)
        "Complete one easy health habit now to build momentum for tonight.",
      if (m.habitCompletionPercent >= 60)
        "Protect your streak by finishing hydration or sleep prep before evening.",
      if (m.focusScore < 60)
        "Do a 2-minute breathing reset before your next task to lower mental load.",
      if (m.productivityScore < 60)
        "Use a 25-minute timer and keep your phone out of reach.",
    ].where((e) => e.trim().isNotEmpty).toSet().toList();
    if (fallback.length < 3) {
      fallback.addAll([
        "Drink a glass of water now and set a reminder for the next hour.",
        "Aim for a consistent bedtime tonight to improve tomorrow's focus and mood.",
      ]);
    }
    return fallback.take(4).toList();
  }

  Future<void> _loadAiSuggestions() async {
    if (_loadingAi) return;
    setState(() => _loadingAi = true);
    try {
      final ai = await GeminiService.generateSuggestions(
        todayMinutes: widget.metrics.screenMinutes,
        averageMinutes: widget.metrics.averageMinutes,
        focusScore: widget.metrics.focusScore,
        productivityScore: widget.metrics.productivityScore,
      );
      if (!mounted) return;
      final merged = [...ai.where((e) => e.trim().isNotEmpty), ..._fallbackSuggestions(widget.metrics)]
          .toSet()
          .take(4)
          .toList();
      if (merged.isNotEmpty) {
        setState(() {
          _suggestions = merged;
          if (_selectedSuggestionIndex >= _suggestions.length) {
            _selectedSuggestionIndex = 0;
          }
        });
      }
    } catch (_) {
      // Keep fallback suggestions when AI is unavailable.
    } finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  void _showPreviousSuggestion() {
    if (_suggestions.isEmpty) return;
    setState(() {
      _selectedSuggestionIndex =
          (_selectedSuggestionIndex - 1 + _suggestions.length) % _suggestions.length;
    });
  }

  void _showNextSuggestion() {
    if (_suggestions.isEmpty) return;
    setState(() {
      _selectedSuggestionIndex = (_selectedSuggestionIndex + 1) % _suggestions.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final insightText = _suggestions.isNotEmpty
        ? _suggestions[_selectedSuggestionIndex]
        : widget.metrics.coachSummaryFallback;
    final insightCount = _suggestions.isNotEmpty ? _suggestions.length : 1;

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
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.greenPale,
                AppColors.greenLight,
                Color(0xFFC7EFCF),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.green.withValues(alpha: 0.5), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insightText,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF165B2E),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${_selectedSuggestionIndex + 1}/$insightCount",
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF165B2E),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: _showPreviousSuggestion,
                      icon: const Icon(Icons.chevron_left, size: 22, color: Color(0xFF165B2E)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: _showNextSuggestion,
                      icon: const Icon(Icons.chevron_right, size: 22, color: Color(0xFF165B2E)),
                    ),
                  ),
                  if (_loadingAi) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF165B2E),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayOverviewCard extends StatelessWidget {
  const _TodayOverviewCard({
    required this.metrics,
    required this.hasUsagePermission,
  });

  final DashboardMetrics metrics;
  final bool hasUsagePermission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenLabel = !hasUsagePermission
        ? "—"
        : metrics.hasUsageData
            ? formatMinutes(metrics.screenMinutes)
            : "Ready to start";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.greenHeroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.heroGreenShadow,
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
              const Icon(Icons.dashboard_outlined, color: AppColors.greenHeroCaption, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's overview",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.greenHeroBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      screenLabel,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.greenHeroTitle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metrics.screenTimeSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.greenHeroBody,
                      ),
                    ),
                    if (!metrics.hasUsageData) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: const [
                          _StartHintChip(icon: Icons.smartphone, label: "Open Time tab"),
                          _StartHintChip(icon: Icons.check_circle_outline, label: "Log 1 habit"),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (metrics.hasUsageData)
                Text(
                  "${(metrics.screenProgress * 100).round()}%",
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: AppColors.greenHeroScore,
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
              GreenHeroMetricTile(
                icon: Icons.track_changes_outlined,
                label: "Productivity",
                value: metrics.hasUsageData ? "${metrics.productivityScore}" : "—",
                progress: metrics.hasUsageData ? metrics.productivityScore / 100 : 0,
              ),
              GreenHeroMetricTile(
                icon: Icons.center_focus_strong,
                label: "Focus",
                value: metrics.hasUsageData ? "${metrics.focusScore}" : "—",
                progress: metrics.hasUsageData ? metrics.focusScore / 100 : 0,
              ),
              GreenHeroMetricTile(
                icon: Icons.calendar_view_week_rounded,
                label: "Habits",
                value: "${metrics.habitCompletionPercent}%",
                progress: metrics.habitCompletionPercent / 100,
              ),
              GreenHeroMetricTile(
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

class _FirstOpenStarterCard extends StatelessWidget {
  const _FirstOpenStarterCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final welcome = AppColors.welcomeStarterCard(AppColors.themeBrightness(theme));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: welcome.gradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: welcome.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome, color: welcome.step, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Welcome to your personal dashboard",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: welcome.title,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Complete these quick steps to unlock AI insights and your daily health score.",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: welcome.body,
            ),
          ),
          const SizedBox(height: 12),
          const _StarterStepRow(
            icon: Icons.looks_one_rounded,
            text: "Grant usage access in the Time tab",
          ),
          const SizedBox(height: 8),
          const _StarterStepRow(
            icon: Icons.looks_two_rounded,
            text: "Log your first habit in the Habits tab",
          ),
          const SizedBox(height: 8),
          const _StarterStepRow(
            icon: Icons.looks_3_rounded,
            text: "Pull down to refresh your first insights",
          ),
        ],
      ),
    );
  }
}

class _StarterStepRow extends StatelessWidget {
  const _StarterStepRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stepColor = AppColors.welcomeStarterCard(AppColors.themeBrightness(theme)).step;
    return Row(
      children: [
        Icon(icon, size: 18, color: stepColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: stepColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _StartHintChip extends StatelessWidget {
  const _StartHintChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: AppColors.greenHeroChip(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.greenHeroCaption),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppColors.greenHeroTileLabel().copyWith(fontSize: 11),
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
    final b = AppColors.themeBrightness(theme);
    final productivity = AppColors.scoreProductivity(b);
    final focus = AppColors.scoreFocus(b);
    final habitBanner = AppColors.habitCompletionBanner(b);

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
                  background: productivity.background,
                  foreground: productivity.foreground,
                  track: productivity.track,
                  border: productivity.border,
                  showDash: !metrics.hasUsageData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ScoreTile(
                  score: metrics.hasUsageData ? metrics.focusScore : 0,
                  label: "Focus",
                  background: focus.background,
                  foreground: focus.foreground,
                  track: focus.track,
                  border: focus.border,
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
            gradient: habitBanner.gradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: habitBanner.border),
          ),
          child: Column(
            children: [
              Text(
                "${metrics.habitCompletionPercent}",
                style: theme.textTheme.displayMedium?.copyWith(
                  color: habitBanner.value,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Weekly habit completion %",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: habitBanner.subtitle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metrics.habitSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: habitBanner.subtitle,
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
    required this.border,
    this.showDash = false,
  });

  final int score;
  final String label;
  final Color background;
  final Color foreground;
  final Color track;
  final Color border;
  final bool showDash;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
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
              color: AppColors.isDarkTheme(theme)
                  ? AppColors.darkOnSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant,
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
  const _TodayMetricsGrid({
    required this.metrics,
    required this.hasUsagePermission,
  });

  final DashboardMetrics metrics;
  final bool hasUsagePermission;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _MetricDetailCard(
              title: "Screen time",
              value: !hasUsagePermission
                  ? "—"
                  : metrics.hasUsageData
                      ? formatMinutes(metrics.screenMinutes)
                      : "—",
              subtitle: !hasUsagePermission
                  ? "Enable usage access above"
                  : metrics.screenTimeSubtitle,
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
    final colors = AppColors.insightAmber(AppColors.themeBrightness(theme));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, color: colors.icon, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.text,
                height: 1.4,
                fontWeight: FontWeight.w500,
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
