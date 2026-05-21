/// Preset mood the user can pick when logging a day.
class MoodType {
  const MoodType({
    required this.id,
    required this.label,
    required this.emoji,
    required this.defaultScore,
  });

  final String id;
  final String label;
  final String emoji;
  /// Default 1–10 intensity used for the weekly chart bar height.
  final double defaultScore;
}
