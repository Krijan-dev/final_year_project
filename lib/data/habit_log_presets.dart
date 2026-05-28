import "package:life_pattern_tracker/models/habit_log_preset.dart";
import "package:life_pattern_tracker/utils/habit_log_details_formatter.dart";

/// Preset activities users can log (aligned with weekly habits).
abstract final class HabitLogPresets {
  static HabitLogPreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  static const List<HabitLogPreset> all = [
    HabitLogPreset(
      id: "meditation",
      emoji: "🧘",
      label: "Meditate",
      title: "Meditation",
      amountUnit: HabitLogAmountUnit.minutes,
    ),
    HabitLogPreset(
      id: "workout",
      emoji: "💪",
      label: "Workout",
      title: "Workout",
      amountUnit: HabitLogAmountUnit.minutes,
    ),
    HabitLogPreset(
      id: "walk",
      emoji: "🚶",
      label: "Walk",
      title: "Walk",
      amountUnit: HabitLogAmountUnit.minutes,
    ),
    HabitLogPreset(
      id: "water",
      emoji: "💧",
      label: "Water",
      title: "Drank water",
      amountUnit: HabitLogAmountUnit.glasses,
      timeOptional: true,
    ),
    HabitLogPreset(
      id: "meal",
      emoji: "🥗",
      label: "Healthy meal",
      title: "Healthy meal",
      amountUnit: HabitLogAmountUnit.freeText,
    ),
    HabitLogPreset(
      id: "sleep",
      emoji: "🌙",
      label: "Sleep",
      title: "Sleep",
      amountUnit: HabitLogAmountUnit.hours,
      timeOptional: true,
    ),
    HabitLogPreset(
      id: "read",
      emoji: "📖",
      label: "Reading",
      title: "Reading",
      amountUnit: HabitLogAmountUnit.minutes,
    ),
    HabitLogPreset(
      id: "mood",
      emoji: "😊",
      label: "Mood check",
      title: "Mood check-in",
      amountUnit: HabitLogAmountUnit.freeText,
      timeOptional: true,
    ),
    HabitLogPreset(
      id: "screen_break",
      emoji: "📵",
      label: "Screen break",
      title: "Screen break",
      amountUnit: HabitLogAmountUnit.minutes,
    ),
    HabitLogPreset(
      id: "study",
      emoji: "📚",
      label: "Study / focus",
      title: "Study session",
      amountUnit: HabitLogAmountUnit.minutes,
    ),
    HabitLogPreset(
      id: "stretch",
      emoji: "🤸",
      label: "Stretch",
      title: "Stretching",
      amountUnit: HabitLogAmountUnit.minutes,
    ),
    HabitLogPreset(
      id: "journal",
      emoji: "📝",
      label: "Journal",
      title: "Journaling",
      amountUnit: HabitLogAmountUnit.freeText,
    ),
  ];
}
