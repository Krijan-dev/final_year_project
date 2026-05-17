import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/habit_tracker_habit.dart";
import "package:life_pattern_tracker/models/mood_day.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";

const Color _kHabitGreen = Color(0xFF22C55E);
const Color _kHabitGreenDark = Color(0xFF16A34A);
const Color _kDayIncomplete = Color(0xFFE5E7EB);
const Color _kMoodPink = Color(0xFFF9A8D4);
const Color _kAddBlue = Color(0xFF2563EB);

class HabitScreen extends ConsumerWidget {
  const HabitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitTrackerProvider);
    final notifier = ref.read(habitTrackerProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _HabitHeader(),
          const SizedBox(height: 16),
          _WeeklyProgressCard(percent: state.weeklyProgressPercent),
          const SizedBox(height: 16),
          _ThisWeeksHabitsCard(
            habits: state.habits,
            onToggleDay: notifier.toggleHabitDay,
          ),
          const SizedBox(height: 16),
          _MoodThisWeekCard(
            days: state.moodDays,
            average: state.averageMood,
          ),
          const SizedBox(height: 16),
          _TodaysLogCard(
            logs: state.logs,
            onAdd: () => _showAddLogSheet(context, ref),
          ),
        ],
      ),
    );
  }

  static void _showAddLogSheet(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final subtitleCtrl = TextEditingController();
    var emoji = "✅";

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Add log entry", style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: subtitleCtrl,
                decoration: const InputDecoration(
                  labelText: "Details (e.g. 15 min)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: "Emoji",
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => emoji = v.isEmpty ? "✅" : v.substring(0, 1),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  ref.read(habitTrackerProvider.notifier).addLog(
                        title: title,
                        subtitle: subtitleCtrl.text.trim().isEmpty
                            ? "Logged"
                            : subtitleCtrl.text.trim(),
                        emoji: emoji,
                      );
                  Navigator.pop(ctx);
                },
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HabitHeader extends StatelessWidget {
  const _HabitHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Habit Tracker",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Build better habits, one day at a time",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kHabitGreen, _kHabitGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kHabitGreen.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weekly Progress",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$percent%",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.black.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Keep up the great work!",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ThisWeeksHabitsCard extends StatelessWidget {
  const _ThisWeeksHabitsCard({
    required this.habits,
    required this.onToggleDay,
  });

  final List<HabitTrackerHabit> habits;
  final void Function(String habitId, int dayIndex) onToggleDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This Week's Habits",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...List.generate(habits.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i == habits.length - 1 ? 0 : 20),
                child: _HabitWeekRow(
                  habit: habits[i],
                  onToggleDay: onToggleDay,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HabitWeekRow extends StatelessWidget {
  const _HabitWeekRow({
    required this.habit,
    required this.onToggleDay,
  });

  final HabitTrackerHabit habit;
  final void Function(String habitId, int dayIndex) onToggleDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: habit.iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "${habit.completedDays}/7 days",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              "${habit.percent}%",
              style: theme.textTheme.titleSmall?.copyWith(
                color: _kHabitGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(7, (i) {
            final done = habit.weekCompleted[i];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => onToggleDay(habit.id, i),
                      child: AspectRatio(
                        aspectRatio: 2.2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: done ? _kHabitGreen : _kDayIncomplete,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: done
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      HabitTrackerHabit.dayLabels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _MoodThisWeekCard extends StatelessWidget {
  const _MoodThisWeekCard({
    required this.days,
    required this.average,
  });

  final List<MoodDay> days;
  final double average;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxScore = 10.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Mood This Week",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final barHeight = 48.0 * (day.score / maxScore).clamp(0.15, 1.0);
                return Expanded(
                  child: Column(
                    children: [
                      Text(day.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: _kMoodPink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Center(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: "Average Mood: "),
                    TextSpan(
                      text: "${average.toStringAsFixed(1)}/10",
                      style: const TextStyle(
                        color: Color(0xFFEC4899),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaysLogCard extends StatelessWidget {
  const _TodaysLogCard({
    required this.logs,
    required this.onAdd,
  });

  final List<TodayLogEntry> logs;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's Log",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAddBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              Text(
                "No entries yet. Tap Add to log a habit.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...logs.map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LogRow(entry: log),
                  )),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry});

  final TodayLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.5 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(entry.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  entry.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            entry.timeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
