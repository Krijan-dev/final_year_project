import "package:life_pattern_tracker/models/usage_session_model.dart";

class AppUsageModel {
  const AppUsageModel({
    required this.appName,
    required this.packageName,
    required this.usageTime,
    required this.lastUsedEpochMillis,
    required this.category,
    this.totalTimeMs = 0,
    this.buckets = const [],
  });

  final String appName;
  final String packageName;
  /// Screen time in whole minutes (from native totalTime / usageTime).
  final int usageTime;
  final int lastUsedEpochMillis;
  final String category;
  final int totalTimeMs;
  final List<UsageSessionModel> buckets;

  factory AppUsageModel.fromMap(Map<String, dynamic> map) {
    final totalMs = (map["totalTime"] as num?)?.round() ?? 0;
    final usageMinutes = (map["usageTime"] as num?)?.round() ??
        (totalMs > 0 ? (totalMs / 60000).floor() : 0);

    final buckets = (map["buckets"] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => UsageSessionModel.fromMap(Map<String, dynamic>.from(e)))
        .where((s) => s.durationMs > 0)
        .toList();

    return AppUsageModel(
      appName: map["appName"] as String? ?? "Unknown App",
      packageName: (map["packageName"] as String?)?.trim() ?? "",
      usageTime: usageMinutes < 0 ? 0 : usageMinutes,
      lastUsedEpochMillis: (map["lastUsed"] as num?)?.round() ?? 0,
      category: map["category"] as String? ?? "other",
      totalTimeMs: totalMs < 0 ? 0 : totalMs,
      buckets: buckets,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "appName": appName,
      "packageName": packageName,
      "usageTime": usageTime,
      if (totalTimeMs > 0) "totalTime": totalTimeMs,
      "lastUsed": lastUsedEpochMillis,
      "category": category,
      "buckets": buckets.map((e) => e.toMap()).toList(),
    };
  }
}
