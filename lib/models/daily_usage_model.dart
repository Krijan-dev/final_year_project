import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/utils/today_date.dart";

class DailyUsageModel {
  const DailyUsageModel({
    required this.date,
    required this.totalScreenTime,
    required this.appUsages,
    required this.hourlyUsageMinutes,
    this.screenTimeSource,
  });

  final DateTime date;
  final int totalScreenTime;
  final List<AppUsageModel> appUsages;
  final List<int> hourlyUsageMinutes;
  /// How screen time was read (phone Usage Access).
  final String? screenTimeSource;

  static DateTime _parseUsageDate(String? raw) {
    if (raw == null || raw.isEmpty) return TodayDate.startOfToday();
    final trimmed = raw.trim();
    if (RegExp(r"^\d{4}-\d{2}-\d{2}$").hasMatch(trimmed)) {
      final parts = trimmed.split("-");
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) return TodayDate.startOfToday();
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  factory DailyUsageModel.fromMap(Map<String, dynamic> map) {
    final apps = (map["apps"] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => AppUsageModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.usageTime.compareTo(a.usageTime));

    final hours = (map["hourlyUsageMinutes"] as List<dynamic>? ?? <dynamic>[])
        .map((e) => (e as num).round())
        .toList();
    final date = _parseUsageDate(map["date"] as String?);
    if (hours.length != 24) {
      final normalized = List<int>.filled(24, 0);
      for (var i = 0; i < hours.length && i < 24; i++) {
        normalized[i] = hours[i];
      }
      return DailyUsageModel(
        date: date,
        totalScreenTime: (map["totalScreenTime"] as num?)?.round() ?? 0,
        appUsages: apps,
        hourlyUsageMinutes: normalized,
        screenTimeSource: map["screenTimeSource"] as String?,
      );
    }

    return DailyUsageModel(
      date: date,
      totalScreenTime: (map["totalScreenTime"] as num?)?.round() ?? 0,
      appUsages: apps,
      hourlyUsageMinutes: hours,
      screenTimeSource: map["screenTimeSource"] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "date": TodayDate.dayKeyFor(date),
      "totalScreenTime": totalScreenTime,
      if (screenTimeSource != null) "screenTimeSource": screenTimeSource,
      "apps": appUsages.map((e) => e.toMap()).toList(),
      "hourlyUsageMinutes": hourlyUsageMinutes,
    };
  }
}
