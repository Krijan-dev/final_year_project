import "package:intl/intl.dart";

String formatMinutes(int minutes) {
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return "${mins}m";
  return "${hours}h ${mins}m";
}

String formatDateShort(DateTime date) => DateFormat("EEE, d MMM").format(date);
