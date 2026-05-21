/// One day in the weekly mood row.
class MoodDay {
  const MoodDay({
    required this.label,
    required this.emoji,
    required this.score,
    this.moodTypeId,
    this.moodTypeLabel,
  });

  final String label;
  final String emoji;
  /// 0–10 scale for bar height.
  final double score;
  final String? moodTypeId;
  final String? moodTypeLabel;

  bool get hasMood => score > 0 && moodTypeId != null;
}
