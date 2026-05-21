import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/weekly_habit.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";

class HabitsState {
  const HabitsState({this.habits = const []});

  final List<WeeklyHabit> habits;
}

/// Dashboard habit metrics derived from the Habit tab tracker.
final habitsProvider = Provider<HabitsState>((ref) {
  final tracker = ref.watch(habitTrackerProvider);
  if (!tracker.ready) return const HabitsState();
  final habits = tracker.habits
      .map(
        (h) => WeeklyHabit(
          emoji: h.emoji,
          name: h.name,
          completedDays: h.completedDays,
          streakDays: h.currentStreak(),
          useGradientFill: h.completedDays >= 4,
        ),
      )
      .toList();
  return HabitsState(habits: habits);
});

final habitsMetricsProvider = Provider<HabitsMetrics>((ref) {
  final tracker = ref.watch(habitTrackerProvider);
  final habits = ref.watch(habitsProvider).habits;
  return HabitsMetrics(
    weeklyCompletionPercent: tracker.weeklyProgressPercent,
    bestStreakDays: tracker.bestStreakDays,
    habits: habits,
  );
});

class HabitsMetrics {
  const HabitsMetrics({
    required this.weeklyCompletionPercent,
    required this.bestStreakDays,
    required this.habits,
  });

  final int weeklyCompletionPercent;
  final int bestStreakDays;
  final List<WeeklyHabit> habits;

  static const int streakGoalDays = 30;

  double get weeklyCompletionProgressFraction =>
      weeklyCompletionPercent / 100;

  double get bestStreakProgressFraction =>
      (bestStreakDays / streakGoalDays).clamp(0.0, 1.0);
}
