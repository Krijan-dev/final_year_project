import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/weekly_habit.dart";

class HabitsState {
  const HabitsState({this.habits = WeeklyHabit.sampleThisWeek});

  final List<WeeklyHabit> habits;

  HabitsState copyWith({List<WeeklyHabit>? habits}) {
    return HabitsState(habits: habits ?? this.habits);
  }
}

/// Local weekly habits (sample data until persisted or synced).
class HabitsNotifier extends StateNotifier<HabitsState> {
  HabitsNotifier() : super(const HabitsState());

  /// Same idea as [UsageNotifier.productivityScore] / [UsageNotifier.focusScore]: derived metric for UI.
  int weeklyCompletionPercent() => WeeklyHabit.weeklyCompletionPercent(state.habits);

  /// Same pattern as scores derived from today’s data — best streak across configured habits.
  int bestStreakDays() => WeeklyHabit.bestStreakAmong(state.habits);

  /// Placeholder for pull-to-refresh / future persistence (mirrors usage refresh hook).
  Future<void> refresh() async {
    // Re-seed sample rows when storage is added, replace with Hive read.
    state = state.copyWith(habits: List<WeeklyHabit>.from(WeeklyHabit.sampleThisWeek));
  }
}

final habitsProvider = StateNotifierProvider<HabitsNotifier, HabitsState>((ref) {
  return HabitsNotifier();
});
