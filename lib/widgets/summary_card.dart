import "package:flutter/material.dart";

/// Shared min height so dashboard metric cards align in a grid.
const double kDashboardMetricCardHeight = 148;

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.progress,
    this.uniformHeight = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  /// Progress from 0.0 to 1.0; shown as a bar at the bottom when set.
  final double? progress;
  /// When true, uses [kDashboardMetricCardHeight] so paired cards match size.
  final bool uniformHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.primary;
    final track = theme.colorScheme.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.45 : 0.85,
    );
    final fraction = progress?.clamp(0.0, 1.0);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: cardColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cardColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        if (fraction != null) ...[
          const SizedBox(height: 12),
          _SummaryProgressBar(
            progress: fraction,
            fillColor: cardColor,
            trackColor: track,
          ),
        ],
      ],
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: uniformHeight
            ? SizedBox(
                height: kDashboardMetricCardHeight,
                child: content,
              )
            : content,
      ),
    );
  }
}

class _SummaryProgressBar extends StatelessWidget {
  const _SummaryProgressBar({
    required this.progress,
    required this.fillColor,
    required this.trackColor,
  });

  final double progress;
  final Color fillColor;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: progress),
      builder: (context, value, _) {
        final v = value.clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: trackColor),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: constraints.maxWidth * v,
                        height: 8,
                        child: ColoredBox(color: fillColor),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
