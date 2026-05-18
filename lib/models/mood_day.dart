/// One day in the weekly mood row.
class MoodDay {
  const MoodDay({
    required this.label,
    required this.emoji,
    required this.score,
  });

  final String label;
  final String emoji;
  /// 0–10 scale for bar height.
  final double score;
}
