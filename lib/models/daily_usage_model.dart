import "app_usage_model.dart";

class DailyUsageModel {
  const DailyUsageModel({
    required this.date,
    required this.totalScreenTime,
    required this.appUsages,
    required this.hourlyUsageMinutes,
  });

  final DateTime date;
  final int totalScreenTime;
  final List<AppUsageModel> appUsages;
  final List<int> hourlyUsageMinutes;

  factory DailyUsageModel.fromMap(Map<String, dynamic> map) {
    final apps = (map["apps"] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => AppUsageModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.usageTime.compareTo(a.usageTime));

    final hours = (map["hourlyUsageMinutes"] as List<dynamic>? ?? <dynamic>[])
        .map((e) => (e as num).round())
        .toList();
    if (hours.length != 24) {
      final normalized = List<int>.filled(24, 0);
      for (var i = 0; i < hours.length && i < 24; i++) {
        normalized[i] = hours[i];
      }
      return DailyUsageModel(
        date: DateTime.tryParse(map["date"] as String? ?? "") ?? DateTime.now(),
        totalScreenTime: (map["totalScreenTime"] as num?)?.round() ?? 0,
        appUsages: apps,
        hourlyUsageMinutes: normalized,
      );
    }

    return DailyUsageModel(
      date: DateTime.tryParse(map["date"] as String? ?? "") ?? DateTime.now(),
      totalScreenTime: (map["totalScreenTime"] as num?)?.round() ?? 0,
      appUsages: apps,
      hourlyUsageMinutes: hours,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "date": DateTime(date.year, date.month, date.day).toIso8601String(),
      "totalScreenTime": totalScreenTime,
      "apps": appUsages.map((e) => e.toMap()).toList(),
      "hourlyUsageMinutes": hourlyUsageMinutes,
    };
  }
}
