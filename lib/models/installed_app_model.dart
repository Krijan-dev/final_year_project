class InstalledAppModel {
  const InstalledAppModel({
    required this.appName,
    required this.packageName,
    required this.category,
  });

  final String appName;
  final String packageName;
  final String category;

  factory InstalledAppModel.fromMap(Map<String, dynamic> map) {
    return InstalledAppModel(
      appName: map["appName"] as String? ?? "Unknown App",
      packageName: map["packageName"] as String? ?? "",
      category: map["category"] as String? ?? "other",
    );
  }
}

