import "package:flutter/material.dart";

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

  static const List<String> dayLabels = [
    "Mon",
    "Tue",
    "Wed",
    "Thu",
    "Fri",
    "Sat",
    "Sun",
  ];
}
