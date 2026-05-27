/// Per-app daily screen time cap (local only; not synced to cloud).
class AppScreenTimeLimit {
  const AppScreenTimeLimit({
    required this.packageName,
    required this.displayName,
    required this.limitMinutesPerDay,
    this.notifyWhenExceeded = true,
  });

  final String packageName;
  final String displayName;
  final int limitMinutesPerDay;
  final bool notifyWhenExceeded;

  static const int minMinutes = 5;
  static const int maxMinutes = 24 * 60;

  Map<String, dynamic> toMap() => {
        "packageName": packageName,
        "displayName": displayName,
        "limitMinutesPerDay": limitMinutesPerDay,
        "notifyWhenExceeded": notifyWhenExceeded,
      };

  factory AppScreenTimeLimit.fromMap(Map<String, dynamic> map) {
    return AppScreenTimeLimit(
      packageName: map["packageName"] as String? ?? "",
      displayName: map["displayName"] as String? ?? "",
      limitMinutesPerDay: (map["limitMinutesPerDay"] as num?)?.round() ?? 60,
      notifyWhenExceeded: map["notifyWhenExceeded"] as bool? ?? true,
    );
  }

  AppScreenTimeLimit copyWith({
    String? packageName,
    String? displayName,
    int? limitMinutesPerDay,
    bool? notifyWhenExceeded,
  }) {
    return AppScreenTimeLimit(
      packageName: packageName ?? this.packageName,
      displayName: displayName ?? this.displayName,
      limitMinutesPerDay: limitMinutesPerDay ?? this.limitMinutesPerDay,
      notifyWhenExceeded: notifyWhenExceeded ?? this.notifyWhenExceeded,
    );
  }
}
