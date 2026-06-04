/// Local-calendar "today" helpers (avoid showing yesterday's cached usage).
abstract final class TodayDate {
  static DateTime get now => DateTime.now();

  static DateTime startOfToday() =>
      DateTime(now.year, now.month, now.day);

  static String get dayKey =>
      "${now.year}-${now.month.toString().padLeft(2, "0")}-${now.day.toString().padLeft(2, "0")}";

  static String dayKeyFor(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, "0")}-${date.day.toString().padLeft(2, "0")}";

  static bool isSameLocalDay(DateTime date) =>
      date.year == now.year && date.month == now.month && date.day == now.day;

  static bool isSameLocalDayKey(String key) => key == dayKey;
}
