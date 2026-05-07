import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/widgets/usage_bar_chart.dart";

class ChartsScreen extends ConsumerWidget {
  const ChartsScreen({super.key});

  String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return "$mins min";
    }

    return "$hours hr $mins min";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);
    final today = state.today;
    final history = state.history;

    final week = history.length <= 7
        ? history
        : history.sublist(history.length - 7);

    final weekValues = week.map((d) => d.totalScreenTime).toList();
    final hourly = today?.hourlyUsageMinutes ?? List<int>.filled(24, 0);

    final maxHourly = hourly.fold<int>(0, (a, b) => a > b ? a : b);
    final maxWeekly =
        weekValues.isEmpty ? 0 : weekValues.reduce((a, b) => a > b ? a : b);

    final todayScreenTime = today?.totalScreenTime ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F7FF),
        elevation: 0,
        title: const Text(
          "Insights",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                "LP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF6FC3FF)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today’s Screen Time",
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  formatMinutes(todayScreenTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Tap hourly bars to view exact usage",
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _chartCard(
            context,
            title: "Hourly Screen Time",
            subtitle: "Tap any bar to see usage time",
            icon: Icons.schedule,
            child: TappableHourlyBarChart(
              values: hourly,
              maxY: maxHourly == 0 ? 1 : maxHourly,
            ),
          ),

          const SizedBox(height: 16),

          _chartCard(
            context,
            title: "7-Day Screen Time",
            subtitle: "Weekly usage trend",
            icon: Icons.bar_chart,
            child: UsageBarChart(
              values: weekValues.isEmpty ? [0] : weekValues,
              maxY: maxWeekly == 0 ? 1 : maxWeekly,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            "Lifestyle Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: const [
              CircleProgressChart(
                title: "Focus Score",
                value: "82%",
                progress: 0.82,
                icon: Icons.center_focus_strong,
                color: Colors.blue,
              ),
              CircleProgressChart(
                title: "Sleep Goal",
                value: "75%",
                progress: 0.75,
                icon: Icons.bedtime,
                color: Colors.deepPurple,
              ),
              CircleProgressChart(
                title: "Water Intake",
                value: "70%",
                progress: 0.70,
                icon: Icons.water_drop,
                color: Colors.cyan,
              ),
              CircleProgressChart(
                title: "Steps Goal",
                value: "68%",
                progress: 0.68,
                icon: Icons.directions_walk,
                color: Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      "AI Lifestyle Insight",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  "Your screen time is slightly high today. Try using Focus Mode for 30 minutes and reduce late-night phone usage to improve sleep quality.",
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF2FF),
                child: Icon(icon, color: Colors.blue),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class TappableHourlyBarChart extends StatelessWidget {
  final List<int> values;
  final int maxY;

  const TappableHourlyBarChart({
    super.key,
    required this.values,
    required this.maxY,
  });

  String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return "$mins min";
    }

    return "$hours hr $mins min";
  }

  void showTimePopup(BuildContext context, int hour, int minutes) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text("Hour ${hour.toString().padLeft(2, "0")}:00"),
          content: Text(
            "Screen time used: ${formatMinutes(minutes)}",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeMaxY = maxY == 0 ? 1 : maxY;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        final value = values[index];
        final barHeight = (value / safeMaxY) * 170;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              showTimePopup(context, index, value);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: barHeight < 6 ? 6 : barHeight,
                  width: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  index.toString(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class CircleProgressChart extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final IconData icon;
  final Color color;

  const CircleProgressChart({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 85,
                width: 85,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 9,
                  backgroundColor: const Color(0xFFEAF2FF),
                  color: color,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}