import "package:intl/intl.dart";

String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return "${mins}m";
  return "${hours}h ${mins}m";
}

/// Formats milliseconds as `0h 0m` (Digital Wellbeing style).
String formatDurationMs(int milliseconds) {
  if (milliseconds <= 0) return "0h 0m";
  final totalMinutes = milliseconds ~/ 60000;
  final hours = totalMinutes ~/ 60;
  final mins = totalMinutes % 60;
  return "${hours}h ${mins}m";
}

/// Alias for event-based screen time totals.
String formatScreenTimeFromMs(int totalTimeMs) => formatDurationMs(totalTimeMs);

String formatDateShort(DateTime date) => DateFormat("EEE, d MMM").format(date);
