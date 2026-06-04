import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/models/usage_session_model.dart";
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
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: _AppSessionsChart(
                buckets: app.buckets,
                barColor: theme.colorScheme.primary,
                labelColor: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// Bar chart of each session’s duration; X-axis labels show session start time.
class _AppSessionsChart extends StatelessWidget {
  const _AppSessionsChart({
    required this.buckets,
    required this.barColor,
    required this.labelColor,
  });

  final List<UsageSessionModel> buckets;
  final Color barColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) return const SizedBox.shrink();

    final timeFmt = DateFormat.Hm();
    final durationsMin = buckets
        .map((b) => (b.durationMs / 60000).ceil().clamp(1, 24 * 60))
        .toList();
    final maxY = durationsMin.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "Sessions today",
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: labelColor),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 148,
          child: BarChart(
            BarChartData(
              maxY: maxY.toDouble() * 1.2,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 8,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final session = buckets[group.x];
                    final start = DateTime.fromMillisecondsSinceEpoch(session.startTimeMs);
                    final end = DateTime.fromMillisecondsSinceEpoch(session.endTimeMs);
                    return BarTooltipItem(
                      "${timeFmt.format(start)} – ${timeFmt.format(end)}\n"
                      "${formatDurationMs(session.durationMs)}",
                      TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 60 ? 30 : (maxY > 15 ? 5 : 1),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: labelColor.withValues(alpha: 0.15),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: maxY > 60 ? 30 : (maxY > 15 ? 5 : 1),
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value > maxY * 1.2) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        "${value.toInt()}m",
                        style: TextStyle(fontSize: 10, color: labelColor),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= buckets.length) {
                        return const SizedBox.shrink();
                      }
                      final start = DateTime.fromMillisecondsSinceEpoch(
                        buckets[i].startTimeMs,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          timeFmt.format(start),
                          style: TextStyle(fontSize: 9, color: labelColor),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: durationsMin.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: barColor,
                      width: buckets.length > 8 ? 10 : 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
