class UsageSessionModel {
  const UsageSessionModel({
    required this.startTimeMs,
    required this.endTimeMs,
    required this.durationMs,
  });

  final int startTimeMs;
  final int endTimeMs;
  final int durationMs;

  factory UsageSessionModel.fromMap(Map<String, dynamic> map) {
    final start = (map["startTime"] as num?)?.round() ?? 0;
    final end = (map["endTime"] as num?)?.round() ?? 0;
    var duration = (map["duration"] as num?)?.round() ?? 0;
    if (duration <= 0 && end > start) {
      duration = end - start;
    }
    if (duration < 0) duration = 0;
    return UsageSessionModel(
      startTimeMs: start,
      endTimeMs: end,
      durationMs: duration,
    );
  }

  Map<String, dynamic> toMap() => {
        "startTime": startTimeMs,
        "endTime": endTimeMs,
        "duration": durationMs,
      };
}

class PackageScreenTimeModel {
  const PackageScreenTimeModel({
    required this.packageName,
    required this.totalTimeMs,
    required this.buckets,
    this.lastUsedMs = 0,
  });

  final String packageName;
  final int totalTimeMs;
  final List<UsageSessionModel> buckets;
  final int lastUsedMs;

  int get totalMinutes => (totalTimeMs / 60000).floor();

  factory PackageScreenTimeModel.fromMap(Map<String, dynamic> map) {
    final pkg = (map["packageName"] as String?)?.trim() ?? "";
    final total = (map["totalTime"] as num?)?.round() ?? 0;
    final buckets = (map["buckets"] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map>()
        .map((e) => UsageSessionModel.fromMap(Map<String, dynamic>.from(e)))
        .where((s) => s.durationMs > 0)
        .toList();
    final lastUsed = (map["lastUsed"] as num?)?.round() ?? 0;
    return PackageScreenTimeModel(
      packageName: pkg,
      totalTimeMs: total < 0 ? 0 : total,
      buckets: buckets,
      lastUsedMs: lastUsed,
    );
  }
}
