import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";

/// Always-visible usage access status on any Android device.
class UsagePermissionStatusBar extends ConsumerWidget {
  const UsagePermissionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usage = ref.watch(usageProvider);
    final theme = Theme.of(context);
    final granted = usage.hasPermission;
    final bg = granted
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
        : theme.colorScheme.errorContainer.withValues(alpha: 0.35);
    final fg = granted
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onErrorContainer;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              granted ? Icons.verified_user_outlined : Icons.lock_outline,
              size: 20,
              color: fg,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                granted
                    ? "Usage access: On — screen time is read from this phone"
                    : "Usage access: Off — enable below to track screen time",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
