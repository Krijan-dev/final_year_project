/// Row in Today's Log on the Habit tab.
class TodayLogEntry {
  const TodayLogEntry({
    required this.id,
    required this.activityKey,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.dateKey,
  });

  final String id;
  /// Stable key for the activity type (preset id or normalized custom name).
  final String activityKey;
  /// Calendar day for this session (`yyyy-MM-dd`).
  final String dateKey;
  final String emoji;
  final String title;
  final String subtitle;
  final String timeLabel;
}
