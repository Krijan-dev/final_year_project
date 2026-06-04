import "package:flutter/material.dart";
import "package:life_pattern_tracker/services/health_connect_service.dart";

/// Shows last Health Connect update time and a warning when data may be stale.
class HealthFreshnessBanner extends StatelessWidget {
  const HealthFreshnessBanner({super.key, required this.data});

  final HealthConnectData data;

  @override
  Widget build(BuildContext context) {
    final line = data.freshnessSubtitle;
    if (line == null || !data.permissionsGranted) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final stale = data.dataMayBeStale;
    final bg = stale
        ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.55)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65);
    final fg = stale
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final icon = stale ? Icons.sync_problem_outlined : Icons.update;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: stale ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
