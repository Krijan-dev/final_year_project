import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";

/// Shown inline where screen time is displayed when Usage Access is not granted.
class UsageAccessPromptCard extends ConsumerStatefulWidget {
  const UsageAccessPromptCard({super.key, this.compact = false});

  final bool compact;

  @override
  ConsumerState<UsageAccessPromptCard> createState() => _UsageAccessPromptCardState();
}

class _UsageAccessPromptCardState extends ConsumerState<UsageAccessPromptCard> {
  String? _appLabel;
  String? _deviceHint;

  @override
  void initState() {
    super.initState();
    _loadHints();
  }

  Future<void> _loadHints() async {
    final notifier = ref.read(usageProvider.notifier);
    final label = await notifier.applicationLabel();
    final hint = await notifier.usageAccessHint();
    if (!mounted) return;
    setState(() {
      _appLabel = label;
      _deviceHint = hint;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appName = _appLabel ?? "this app";
    final hint = _deviceHint ??
        "Open Usage access in Settings and enable $appName.";

    return Card(
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 14 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Usage access required",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              widget.compact
                  ? "Android needs Usage Access in Settings (not an in-app popup). $hint"
                  : "Screen time is read from Android Usage Access in Settings — every phone uses this, "
                      "but the menu path varies by brand.\n\n$hint",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: widget.compact ? 10 : 12),
            FilledButton.icon(
              onPressed: () => ref.read(usageProvider.notifier).openUsageSettings(),
              icon: const Icon(Icons.settings),
              label: const Text("Open Usage access settings"),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => ref.read(usageProvider.notifier).openApplicationSettings(),
              icon: const Icon(Icons.apps_outlined),
              label: const Text("Open app info (alternate path)"),
            ),
            if (!widget.compact) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => ref.read(usageProvider.notifier).checkPermission(),
                child: const Text("I turned it on — check again"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
