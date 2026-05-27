import "package:flutter/material.dart";
import "package:life_pattern_tracker/utils/week_calendar.dart";

/// Habit with a Mon–Sun completion grid for the Habit tab.
class HabitTrackerHabit {
  const HabitTrackerHabit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.iconBackground,
    required this.weekCompleted,
  }) : assert(weekCompleted.length == 7, "weekCompleted must have 7 days");

  final String id;
  final String name;
  final String emoji;
  final Color iconBackground;
  /// Index 0 = Monday … 6 = Sunday.
  final List<bool> weekCompleted;

  int get completedDays => weekCompleted.where((c) => c).length;

  int get percent => ((completedDays / 7) * 100).round().clamp(0, 100);

  /// Consecutive completed days ending at today (or latest day in the week).
  int currentStreak() {
    final end = WeekCalendar.todayWeekIndex;
    var streak = 0;
    for (var i = end; i >= 0; i--) {
      if (weekCompleted[i]) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static List<String> weekDayLabels() => WeekCalendar.currentWeekDayLabels();
}
