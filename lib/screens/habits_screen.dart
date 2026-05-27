import "package:flutter/material.dart";

/// Accent palette aligned with common habit-tracker UIs (green + mood pink).
const Color _kHabitGreen = Color(0xFF2ECC71);
const Color _kHabitGreenDeep = Color(0xFF27AE60);
const Color _kMoodPink = Color(0xFFFF6B6B);

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  static final List<_WeekHabit> _habits = [
    const _WeekHabit(
      title: "Sleep 8 Hours",
      subtitle: "5/7 days",
      icon: Icons.bedtime_outlined,
      iconColor: Color(0xFF9B59B6),
      completedDays: [true, true, false, true, true, false, true],
      percent: 71,
    ),
    const _WeekHabit(
      title: "Exercise 30 min",
      subtitle: "4/7 days",
      icon: Icons.fitness_center_rounded,
      iconColor: Color(0xFFE74C3C),
      completedDays: [true, false, true, false, true, true, false],
      percent: 57,
    ),
    const _WeekHabit(
      title: "Drink 8 glasses water",
      subtitle: "6/7 days",
      icon: Icons.water_drop_outlined,
      iconColor: Color(0xFF3498DB),
      completedDays: [true, true, true, true, true, true, false],
      percent: 86,
    ),
  ];

  static final List<_MoodDay> _moods = [
    const _MoodDay("Mon", "😐"),
    const _MoodDay("Tue", "😄"),
    const _MoodDay("Wed", "😐"),
    const _MoodDay("Thu", "😄"),
    const _MoodDay("Fri", "☹️"),
    const _MoodDay("Sat", "😄"),
    const _MoodDay("Sun", "😐"),
  ];

  static final List<_LogEntry> _logs = [
    const _LogEntry("Morning Meditation", "15 min", "07:30 AM", Icons.self_improvement_outlined, Color(0xFF9B59B6)),
    const _LogEntry("Healthy Breakfast", "25 min", "08:15 AM", Icons.restaurant_outlined, Color(0xFFE67E22)),
    const _LogEntry("Workout Session", "45 min", "06:00 PM", Icons.fitness_center_rounded, Color(0xFFE74C3C)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        Text(
          "Habit Tracker",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Build better habits, one day at a time",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        const _WeeklyProgressBanner(progress: 0.71),
        const SizedBox(height: 28),
        Text(
          "This Week's Habits",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        ..._habits.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _HabitWeekCard(habit: h),
            )),
        const SizedBox(height: 12),
        Text(
          "Mood This Week",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        _MoodWeekSection(moods: _moods, averageLabel: "Average Mood: 6.5/10"),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              "Today's Log",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Add log — connect storage in a future update.")),
                );
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text("Add"),
              style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._logs.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LogTile(entry: e),
            )),
      ],
    );
  }
}

class _WeeklyProgressBanner extends StatelessWidget {
  const _WeeklyProgressBanner({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: _kHabitGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _kHabitGreen.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weekly Progress",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$pct%",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Keep up the great work!",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.black.withValues(alpha: 0.2),
                    color: _kHabitGreenDeep,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: Icon(Icons.flag_outlined, color: Colors.white.withValues(alpha: 0.95)),
          ),
        ],
      ),
    );
  }
}

class _WeekHabit {
  const _WeekHabit({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.completedDays,
    required this.percent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<bool> completedDays;
  final int percent;
}

class _HabitWeekCard extends StatelessWidget {
  const _HabitWeekCard({required this.habit});

  final _WeekHabit habit;

  static const _days = ["M", "T", "W", "T", "F", "S", "S"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: habit.iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(habit.icon, color: habit.iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.title,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habit.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${habit.percent}%",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: _kHabitGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(7, (i) {
                final done = habit.completedDays[i];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    child: Column(
                      children: [
                        Container(
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: done ? _kHabitGreen : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: done
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _days[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodDay {
  const _MoodDay(this.label, this.emoji);
  final String label;
  final String emoji;
}

class _MoodWeekSection extends StatelessWidget {
  const _MoodWeekSection({required this.moods, required this.averageLabel});

  final List<_MoodDay> moods;
  final String averageLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: moods
                  .map(
                    (m) => Expanded(
                      child: Column(
                        children: [
                          Text(m.emoji, style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 6),
                          Text(
                            m.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: _kMoodPink.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              averageLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _kMoodPink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntry {
  const _LogEntry(this.title, this.duration, this.time, this.icon, this.iconColor);
  final String title;
  final String duration;
  final String time;
  final IconData icon;
  final Color iconColor;
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final _LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: entry.iconColor.withValues(alpha: 0.15),
          child: Icon(entry.icon, color: entry.iconColor, size: 22),
        ),
        title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          entry.duration,
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
        ),
        trailing: Text(
          entry.time,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
