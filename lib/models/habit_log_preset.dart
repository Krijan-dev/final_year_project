import "package:life_pattern_tracker/utils/habit_log_details_formatter.dart";

/// Quick-pick activity for Today's Log on the Habit tab.
class HabitLogPreset {
  const HabitLogPreset({
    required this.id,
    required this.emoji,
    required this.label,
    required this.title,
    required this.amountUnit,
    this.timeOptional = false,
  });

  final String id;
  final String emoji;
  /// Short label shown on the picker chip.
  final String label;
  /// Stored as log title.
  final String title;
  final HabitLogAmountUnit amountUnit;
  /// When true, users can log without a time (e.g. water throughout the day).
  final bool timeOptional;
}
