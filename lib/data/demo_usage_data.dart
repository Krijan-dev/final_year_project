import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";

/// Number of demo days (matches typical 7-day charts in the app).
const int demoWeekDayCount = 7;

/// Heavy social + long screen time so productivity and focus scores drop in the UI.
DailyUsageModel buildDemoDailyUsage() {
  final now = DateTime.now();
  final date = DateTime(now.year, now.month, now.day);
  return buildDemoDailyUsageForDate(date, intensity: 1.0);
}

/// One synthetic day: [date] at local midnight, usage scaled by [intensity].
DailyUsageModel buildDemoDailyUsageForDate(DateTime date, {double intensity = 1.0}) {
  final day = DateTime(date.year, date.month, date.day);
  final lastUsed = day.add(const Duration(hours: 21)).millisecondsSinceEpoch;

  int scaled(int minutes) => (minutes * intensity).round().clamp(1, 9999);

  final apps = [
    AppUsageModel(
      appName: "TikTok",
      packageName: "com.zhiliaoapp.musically",
      usageTime: scaled(195),
      lastUsedEpochMillis: lastUsed,
      category: "social",
    ),
    AppUsageModel(
      appName: "Instagram",
      packageName: "com.instagram.android",
      usageTime: scaled(140),
      lastUsedEpochMillis: lastUsed,
      category: "social",
    ),
    AppUsageModel(
      appName: "Facebook",
      packageName: "com.facebook.katana",
      usageTime: scaled(95),
      lastUsedEpochMillis: lastUsed,
      category: "social",
    ),
    AppUsageModel(
      appName: "YouTube",
      packageName: "com.google.android.youtube",
      usageTime: scaled(85),
      lastUsedEpochMillis: lastUsed,
      category: "video",
    ),
    AppUsageModel(
      appName: "Chrome",
      packageName: "com.android.chrome",
      usageTime: scaled(40),
      lastUsedEpochMillis: lastUsed,
      category: "other",
    ),
    AppUsageModel(
      appName: "Notes",
      packageName: "com.example.notes",
      usageTime: scaled(12),
      lastUsedEpochMillis: lastUsed,
      category: "productivity",
    ),
  ];

  final hourly = List<int>.filled(24, 0);
  for (var h = 12; h <= 22; h++) {
    hourly[h] = ((18 + (h % 4) * 6) * intensity).round();
  }
  hourly[20] = (55 * intensity).round();
  hourly[21] = (62 * intensity).round();

  final total = apps.fold<int>(0, (s, a) => s + a.usageTime);

  return DailyUsageModel(
    date: day,
    totalScreenTime: total,
    appUsages: apps,
    hourlyUsageMinutes: hourly,
  );
}

/// Seven consecutive local calendar days ending today, oldest first (matches Hive sort).
/// Intensity ramps slightly through the week so charts show a trend.
List<DailyUsageModel> buildDemoWeekHistory() {
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);
  final start = todayMidnight.subtract(const Duration(days: demoWeekDayCount - 1));

  return List.generate(demoWeekDayCount, (i) {
    final day = start.add(Duration(days: i));
    // ~0.72 → ~1.0 across the week so 7-day trend is visible
    final intensity = 0.72 + (i / (demoWeekDayCount - 1)) * 0.28;
    return buildDemoDailyUsageForDate(day, intensity: intensity);
  });
}
