import "package:intl/intl.dart";

/// Monday-based calendar helpers for the habit tracker week grid.
abstract final class WeekCalendar {
  static DateTime get _now => DateTime.now();

  /// Monday 00:00 of the current week.
  static DateTime get weekStart {
    final n = _now;
    final weekday = n.weekday; // 1 = Mon … 7 = Sun
    return DateTime(n.year, n.month, n.day).subtract(Duration(days: weekday - 1));
  }

  static String get weekKey {
    final start = weekStart;
    return "${start.year}-${start.month.toString().padLeft(2, "0")}-${start.day.toString().padLeft(2, "0")}";
  }

  static String get todayKey {
    final n = _now;
    return "${n.year}-${n.month.toString().padLeft(2, "0")}-${n.day.toString().padLeft(2, "0")}";
  }

  /// 0 = Monday … 6 = Sunday.
  static int get todayWeekIndex => _now.weekday - 1;

  static List<String> currentWeekDayLabels() {
    final start = weekStart;
    return List.generate(7, (i) {
      final day = start.add(Duration(days: i));
      return DateFormat("E").format(day); // Mon, Tue, …
    });
  }

  static int weekIndexForDateKey(String dateKey) {
    final parts = dateKey.split("-");
    if (parts.length != 3) return todayWeekIndex;
    final date = DateTime(
      int.tryParse(parts[0]) ?? _now.year,
      int.tryParse(parts[1]) ?? _now.month,
      int.tryParse(parts[2]) ?? _now.day,
    );
    final diff = date.difference(weekStart).inDays;
    if (diff < 0 || diff > 6) return -1;
    return diff;
  }
}
