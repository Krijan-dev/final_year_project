import "package:flutter/material.dart";
import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

class AppUsageTile extends StatelessWidget {
  const AppUsageTile({
    super.key,
    required this.app,
    required this.totalMinutes,
  });

  final AppUsageModel app;
  final int totalMinutes;

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return "?";
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final percent = totalMinutes <= 0 ? 0.0 : (app.usageTime / totalMinutes * 100);
    final color = Theme.of(context).colorScheme.primaryContainer;
    final onColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        foregroundColor: onColor,
        child: Text(_initial(app.appName)),
      ),
      title: Text(app.appName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text("${percent.toStringAsFixed(1)}% of total"),
      trailing: Text(
        formatMinutes(app.usageTime),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
