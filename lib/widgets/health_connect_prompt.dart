import "package:flutter/material.dart";
import "package:life_pattern_tracker/services/health_connect_service.dart";
import "package:life_pattern_tracker/widgets/health_freshness_banner.dart";

/// Inline Health Connect setup when SDK missing or permissions not granted.
class HealthConnectPromptCard extends StatelessWidget {
  const HealthConnectPromptCard({
    super.key,
    required this.data,
    required this.onGrantAccess,
    required this.onInstall,
    required this.onRetry,
    this.onOpenFitnessApp,
  });

  final HealthConnectData data;
  final VoidCallback onGrantAccess;
  final VoidCallback onInstall;
  final VoidCallback onRetry;
  final VoidCallback? onOpenFitnessApp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = data.needsInstall
        ? "Health Connect setup"
        : data.needsPermission
            ? "Health Connect permissions"
            : "No health data yet";

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (data.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                data.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              data.syncHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (data.installedFitnessAppNames.isNotEmpty &&
                onOpenFitnessApp != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onOpenFitnessApp,
                icon: const Icon(Icons.directions_walk_outlined),
                label: Text("Open ${data.installedFitnessAppNames.first}"),
              ),
            ],
            const SizedBox(height: 12),
            if (data.needsInstall)
              FilledButton.icon(
                onPressed: onInstall,
                icon: const Icon(Icons.download_outlined),
                label: const Text("Install / open Health Connect"),
              ),
            if (data.needsPermission) ...[
              FilledButton.icon(
                onPressed: onGrantAccess,
                icon: const Icon(Icons.health_and_safety_outlined),
                label: const Text("Allow Steps & Sleep (system dialog)"),
              ),
              const SizedBox(height: 8),
              Text(
                "Android will ask for Steps and Sleep together. If you only see Steps, tap again or open Health Connect and enable Sleep for this app.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
            ],
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Check again"),
            ),
            if (data.permissionsGranted && data.freshnessSubtitle != null) ...[
              const SizedBox(height: 12),
              HealthFreshnessBanner(data: data),
            ],
          ],
        ),
      ),
    );
  }
}
