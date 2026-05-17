/// Row in Today's Log on the Habit tab.
class TodayLogEntry {
  const TodayLogEntry({
    required this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
  });

  final String id;
  final String emoji;
  final String title;
  final String subtitle;
  final String timeLabel;
}
