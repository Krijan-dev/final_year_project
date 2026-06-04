import "package:flutter/material.dart";
import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:intl/intl.dart";

class AppUsageTile extends StatefulWidget {
  const AppUsageTile({
    super.key,
    required this.app,
    required this.totalMinutes,
  });

  final AppUsageModel app;
  final int totalMinutes;

  @override
  State<AppUsageTile> createState() => _AppUsageTileState();
}

class _AppUsageTileState extends State<AppUsageTile> {
  bool _expanded = false;

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return "?";
    return t[0].toUpperCase();
  }

  String _displayTime() {
    if (widget.app.totalTimeMs > 0) {
      return formatDurationMs(widget.app.totalTimeMs);
    }
    return formatMinutes(widget.app.usageTime);
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final percent = widget.totalMinutes <= 0
        ? 0.0
        : (app.usageTime / widget.totalMinutes * 100);
    final color = Theme.of(context).colorScheme.primaryContainer;
    final onColor = Theme.of(context).colorScheme.onPrimaryContainer;
    final theme = Theme.of(context);
    final hasBuckets = app.buckets.isNotEmpty;
    final timeFmt = DateFormat.Hm();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color,
              foregroundColor: onColor,
              child: Text(_initial(app.appName)),
            ),
            title: Text(
              app.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              "${percent.toStringAsFixed(1)}% of total"
              "${hasBuckets ? " · ${app.buckets.length} session${app.buckets.length == 1 ? "" : "s"}" : ""}",
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayTime(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (hasBuckets) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
            onTap: hasBuckets
                ? () => setState(() => _expanded = !_expanded)
                : null,
          ),
          if (_expanded && hasBuckets)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Sessions today",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...app.buckets.map((session) {
                    final start = DateTime.fromMillisecondsSinceEpoch(session.startTimeMs);
                    final end = DateTime.fromMillisecondsSinceEpoch(session.endTimeMs);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "${timeFmt.format(start)} – ${timeFmt.format(end)} · "
                        "${formatDurationMs(session.durationMs)}",
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
