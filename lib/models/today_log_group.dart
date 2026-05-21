import "package:life_pattern_tracker/models/today_log_entry.dart";
import "package:life_pattern_tracker/utils/habit_log_details_formatter.dart";

/// One activity type in Today's Log, possibly with multiple sessions.
class TodayLogGroup {
  const TodayLogGroup({
    required this.activityKey,
    required this.title,
    required this.emoji,
    required this.amountUnit,
    required this.sessions,
  });

  final String activityKey;
  final String title;
  final String emoji;
  final HabitLogAmountUnit amountUnit;
  final List<TodayLogEntry> sessions;

  String get totalSubtitle =>
      HabitLogDetailsFormatter.summarizeTotal(sessions, amountUnit);

  String get timesLabel => HabitLogDetailsFormatter.summarizeTimes(sessions);

  int get sessionCount => sessions.length;
}
