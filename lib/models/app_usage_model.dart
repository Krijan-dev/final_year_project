class AppUsageModel {
  const AppUsageModel({
    required this.appName,
    required this.packageName,
    required this.usageTime,
    required this.lastUsedEpochMillis,
    required this.category,
  });

  final String appName;
  final String packageName;
  final int usageTime;
  final int lastUsedEpochMillis;
  final String category;

  factory AppUsageModel.fromMap(Map<String, dynamic> map) {
    return AppUsageModel(
      appName: map["appName"] as String? ?? "Unknown App",
      packageName: map["packageName"] as String? ?? "",
      usageTime: (map["usageTime"] as num?)?.round() ?? 0,
      lastUsedEpochMillis: (map["lastUsed"] as num?)?.round() ?? 0,
      category: map["category"] as String? ?? "other",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "appName": appName,
      "packageName": packageName,
      "usageTime": usageTime,
      "lastUsed": lastUsedEpochMillis,
      "category": category,
    };
  }
}
