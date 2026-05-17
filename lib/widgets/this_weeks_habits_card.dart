import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/weekly_habit.dart";
import "package:life_pattern_tracker/providers/habits_provider.dart";

/// Weekly habit list (summary metrics live on [DashboardScreen]).
class ThisWeeksHabitsSection extends ConsumerWidget {
  const ThisWeeksHabitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsState = ref.watch(habitsProvider);
    final habits = habitsState.habits;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final track = cs.outlineVariant.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.45 : 0.85,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "This week's habits",
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...List.generate(habits.length, (i) {
                  final h = habits[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: i == habits.length - 1 ? 0 : 16),
                    child: _HabitRow(
                      habit: h,
                      trackColor: track,
                      barColor: Colors.teal,
                      barGradientEnd: Colors.teal.shade700,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HabitRow extends StatelessWidget {
  const _HabitRow({
    required this.habit,
    required this.trackColor,
    required this.barColor,
    required this.barGradientEnd,
  });

  final WeeklyHabit habit;
  final Color trackColor;
  final Color barColor;
  final Color barGradientEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: () {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text("${habit.name} — ${habit.completedDays}/${habit.totalDays} days"),
            behavior: SnackBarBehavior.floating,
            width: 360,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.emoji, style: theme.textTheme.titleMedium),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    habit.name,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "${habit.completedDays}/${habit.totalDays} days",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AnimatedHabitBar(
              target: habit.progressFraction,
              useGradient: habit.useGradientFill,
              trackColor: trackColor,
              solidColor: barColor,
              gradientEnd: barGradientEnd,
            ),
            if (habit.streakDays > 0) ...[
              const SizedBox(height: 6),
              Text(
                "Streak ${habit.streakDays} days",
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedHabitBar extends StatelessWidget {
  const _AnimatedHabitBar({
    required this.target,
    required this.useGradient,
    required this.trackColor,
    required this.solidColor,
    required this.gradientEnd,
  });

  final double target;
  final bool useGradient;
  final Color trackColor;
  final Color solidColor;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: target.clamp(0.0, 1.0)),
      builder: (context, value, _) {
        final v = value.clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 8,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth * v;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: trackColor),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: w,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: useGradient
                                ? LinearGradient(
                                    colors: [solidColor, gradientEnd],
                                  )
                                : null,
                            color: useGradient ? null : solidColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
