import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";

class UsageBarChart extends StatelessWidget {
  const UsageBarChart({
    super.key,
    required this.values,
    required this.maxY,
    this.hourly = false,
  });

  final List<int> values;
  final int maxY;
  final bool hourly;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return BarChart(
      BarChartData(
        maxY: (maxY <= 0 ? 10 : maxY).toDouble() * 1.2,
        barGroups: values
            .asMap()
            .entries
            .map(
              (entry) => BarChartGroupData(
                x: entry.key,
                barRods: [
                  BarChartRodData(
                    toY: entry.value.toDouble(),
                    color: color,
                    width: hourly ? 8 : 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            )
            .toList(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (hourly) {
                  if (value.toInt() % 6 != 0) return const SizedBox.shrink();
                  return Text("${value.toInt()}");
                }
                return Text("#${value.toInt() + 1}");
              },
            ),
          ),
        ),
      ),
    );
  }
}
