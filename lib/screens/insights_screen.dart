import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/insight_models.dart";
import "package:life_pattern_tracker/providers/insights_provider.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";
import "package:life_pattern_tracker/services/gemini_service.dart";
import "package:life_pattern_tracker/widgets/account_avatar_button.dart";
import "package:life_pattern_tracker/widgets/green_hero_metric_tile.dart";

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(insightsProvider);
    final notifier = ref.read(insightsProvider.notifier);
    final state = view.insights;

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (!view.ready) const LinearProgressIndicator(minHeight: 2),
          _InsightsHeader(aiUsesGemini: view.aiUsesGemini),
          const SizedBox(height: 16),
          _HealthRiskScoreCard(
            label: state.healthRiskLabel,
            score: state.healthRiskScore,
            metrics: state.healthMetrics,
          ),
          const SizedBox(height: 16),
          _WellnessScoresSection(
            scores: state.wellnessScores,
            overallScore: state.overallWellnessScore,
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            icon: Icons.analytics_outlined,
            iconColor: Colors.teal,
            title: "Smart Recommendations",
            badge: "Calculated",
          ),
          const SizedBox(height: 12),
          if (state.recommendations.isEmpty)
            const _EmptyInsightNote(message: "Pull down to refresh with usage and habit data.")
          else
            ...state.recommendations.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecommendationCard(item: r),
              ),
            ),
          const SizedBox(height: 8),
          _SectionTitle(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFF7C3AED),
            title: "AI Insights",
            badge: view.aiUsesGemini
                ? "Gemini"
                : view.aiLoading
                    ? "Loading…"
                    : "Calculated",
          ),
          if (view.aiLoading) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 12),
          if (!view.aiLoading && state.aiTips.isEmpty)
            _EmptyInsightNote(
              message: GeminiService.isConfigured
                  ? "No AI tips yet. Pull to refresh."
                  : "Add GEMINI_API_KEY in .env for AI insights.",
            )
          else if (!view.aiLoading)
            ...state.aiTips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AiInsightCard(tip: tip),
              ),
            ),
          const SizedBox(height: 8),
          const _SectionTitle(
            icon: Icons.trending_up,
            iconColor: Color(0xFF2563EB),
            title: "Weekly Trends",
            badge: "Calculated",
          ),
          const SizedBox(height: 12),
          _WeeklyTrendsCard(trends: state.weeklyTrends),
        ],
      ),
    );
  }
}

class _EmptyInsightNote extends StatelessWidget {
  const _EmptyInsightNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _InsightsHeader extends StatelessWidget {
  const _InsightsHeader({required this.aiUsesGemini});

  final bool aiUsesGemini;

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
                "Insights",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const AccountAvatarButton(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          aiUsesGemini
              ? "Calculated scores plus personalized AI tips"
              : "Scores and tips from your usage and habits",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _HealthRiskScoreCard extends StatelessWidget {
  const _HealthRiskScoreCard({
    required this.label,
    required this.score,
    required this.metrics,
  });

  final String label;
  final int score;
  final List<HealthRiskMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = switch (label.toLowerCase()) {
      "low" => "Overall health status looks great!",
      "medium" => "A few areas could use attention this week.",
      "high" => "Consider focusing on sleep, habits, and screen time.",
      _ => "Based on your usage and habit data.",
    };

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
              const Icon(Icons.shield_outlined, color: AppColors.greenHeroCaption, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Health Risk Score",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.greenHeroBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.greenHeroTitle,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.greenHeroBody,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                "$score",
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
            childAspectRatio: 1.65,
            children: metrics
                .map(
                  (m) => GreenHeroMetricTile(
                    icon: m.icon,
                    label: m.label,
                    value: m.status,
                    warning: m.isWarning,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _OverallWellnessCard extends StatelessWidget {
  const _OverallWellnessCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = AppColors.themeBrightness(theme);
    final focus = AppColors.scoreFocus(b);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: focus.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: focus.border),
      ),
      child: Column(
        children: [
          Text(
            "$score",
            style: theme.textTheme.displayMedium?.copyWith(
              color: focus.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Overall Wellness Score",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.isDarkTheme(theme)
                  ? AppColors.darkOnSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WellnessScoresSection extends StatelessWidget {
  const _WellnessScoresSection({
    required this.scores,
    required this.overallScore,
  });

  final List<WellnessScoreItem> scores;
  final int overallScore;

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
              "Wellness Scores",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (scores.length >= 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _WellnessScoreTile(item: scores[0])),
                const SizedBox(width: 12),
                Expanded(child: _WellnessScoreTile(item: scores[1])),
              ],
            ),
          ),
        const SizedBox(height: 12),
        _OverallWellnessCard(score: overallScore),
      ],
    );
  }
}

class _WellnessScoreTile extends StatelessWidget {
  const _WellnessScoreTile({required this.item});

  final WellnessScoreItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = AppColors.themeBrightness(theme);
    final palette = item.label == "Mental"
        ? AppColors.scoreFocus(b)
        : AppColors.scoreProductivity(b);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            "${item.score}",
            style: theme.textTheme.headlineLarge?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.isDarkTheme(theme)
                  ? AppColors.darkOnSurfaceVariant
                  : theme.colorScheme.onSurfaceVariant,
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
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

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.item});

  final SmartRecommendation item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = AppColors.tintedCard(
      AppColors.themeBrightness(theme),
      lightBackground: item.background,
      lightBorder: item.border,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            color: AppColors.isDarkTheme(theme) ? tint.text : item.iconColor,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: tint.text,
                        ),
                      ),
                    ),
                    if (item.priority == RecommendationPriority.high)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "High",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tint.subtitle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tint.subtitle,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.tip});

  final AiInsightTip tip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = AppColors.tintedFromBackground(
      AppColors.themeBrightness(theme),
      tip.background,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            tip.icon,
            color: AppColors.isDarkTheme(theme) ? tint.text : tip.iconColor,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: tint.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tint.subtitle,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip.hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tint.subtitle,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendsCard extends StatelessWidget {
  const _WeeklyTrendsCard({required this.trends});

  final List<WeeklyTrendItem> trends;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = AppColors.themeBrightness(theme);
    final trendsIcon =
        b == Brightness.dark ? AppColors.greenAccent : const Color(0xFF2563EB);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: trendsIcon, size: 22),
                const SizedBox(width: 8),
                Text(
                  "Weekly Trends",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...trends.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TrendRow(item: t),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.item});

  final WeeklyTrendItem item;

  static const double _maxTrendPercent = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = AppColors.themeBrightness(theme);
    final panel = AppColors.subtlePanel(b);
    final neutral = item.changePercent == 0;
    final color = neutral
        ? theme.colorScheme.onSurfaceVariant
        : item.isPositive
            ? (b == Brightness.dark ? AppColors.greenAccent : const Color(0xFF16A34A))
            : const Color(0xFFEF4444);
    final fillFraction = neutral
        ? 0.0
        : (item.changePercent.abs() / _maxTrendPercent).clamp(0.0, 1.0);
    final trackBg = b == Brightness.dark
        ? AppColors.darkSurfaceElevated
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.35);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: panel.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panel.border.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (!neutral)
                Icon(
                  item.isPositive ? Icons.trending_up : Icons.trending_down,
                  color: color,
                  size: 18,
                ),
              if (!neutral) const SizedBox(width: 4),
              Text(
                "${item.changePercent > 0 ? "+" : ""}${item.changePercent}%",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fillWidth = constraints.maxWidth * fillFraction;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(color: trackBg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: fillWidth,
                          height: 8,
                          child: ColoredBox(color: color),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
