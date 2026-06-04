import "dart:io";

import "package:flutter/services.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/models/usage_session_model.dart";
import "package:life_pattern_tracker/utils/app_log.dart";
import "package:life_pattern_tracker/models/installed_app_model.dart";
import "package:life_pattern_tracker/utils/today_date.dart";

class UsageStatsService {
  static const MethodChannel _channel = MethodChannel("life_pattern_tracker/usage");

  Future<bool> hasUsagePermission() async {
    if (!Platform.isAndroid) return false;
    final result = await _channel
        .invokeMethod<bool>("hasUsagePermission")
        .timeout(const Duration(seconds: 10), onTimeout: () => false);
    return result ?? false;
  }

  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>("openUsageAccessSettings");
  }

  Future<void> openApplicationSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>("openApplicationSettings");
  }

  Future<String> getApplicationLabel() async {
    if (!Platform.isAndroid) return "Life Pattern Tracker";
    final label = await _channel.invokeMethod<String>("getApplicationLabel");
    return label?.trim().isNotEmpty == true ? label!.trim() : "Life Pattern Tracker";
  }

  Future<String> getUsageAccessHint() async {
    if (!Platform.isAndroid) {
      return "Enable Usage access for this app in your phone settings.";
    }
    final hint = await _channel.invokeMethod<String>("getUsageAccessHint");
    return hint?.trim().isNotEmpty == true
        ? hint!.trim()
        : "Open Usage access in Settings and enable this app.";
  }

  Future<String> getHealthSyncHint() async {
    if (!Platform.isAndroid) return "";
    final hint = await _channel.invokeMethod<String>("getHealthSyncHint");
    return hint?.trim() ?? "";
  }

  Future<bool> openHealthConnectApp() async {
    if (!Platform.isAndroid) return false;
    final ok = await _channel.invokeMethod<bool>("openHealthConnectApp");
    return ok ?? false;
  }

  Future<bool> openHealthConnectPermissions() async {
    if (!Platform.isAndroid) return false;
    final ok = await _channel.invokeMethod<bool>("openHealthConnectPermissions");
    return ok ?? false;
  }

  /// Shows the system Health Connect dialog for Steps and Sleep together.
  Future<Map<String, dynamic>?> requestHealthConnectPermissions() async {
    if (!Platform.isAndroid) return null;
    try {
      final payload = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        "requestHealthConnectPermissions",
      );
      if (payload == null) return null;
      return Map<String, dynamic>.from(payload);
    } on PlatformException catch (e, st) {
      AppLog.e("requestHealthConnectPermissions failed: ${e.code}", error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> openPrimaryFitnessApp() async {
    if (!Platform.isAndroid) return false;
    final ok = await _channel.invokeMethod<bool>("openPrimaryFitnessApp");
    return ok ?? false;
  }

  /// Direct Health Connect read (accurate permissions + steps/sleep on all Android versions).
  Future<Map<String, dynamic>?> readHealthSummary() async {
    if (!Platform.isAndroid) return null;
    try {
      final payload = await _channel.invokeMethod<Map<dynamic, dynamic>>("readHealthSummary");
      if (payload == null) return null;
      return Map<String, dynamic>.from(payload);
    } on PlatformException catch (e, st) {
      AppLog.e("readHealthSummary failed: ${e.code}", error: e, stackTrace: st);
      return null;
    }
  }

  /// Today only: local midnight → now via [UsageStatsManager.queryEvents] (native).
  Future<List<PackageScreenTimeModel>> getTodayScreenTimeFromEvents() async {
    if (!Platform.isAndroid) return const [];
    try {
      final payload = await _channel
          .invokeMethod<List<dynamic>>("getTodayScreenTimeFromEvents")
          .timeout(const Duration(seconds: 60), onTimeout: () => null);
      if (payload == null || payload.isEmpty) return const [];
      return payload
          .whereType<Map>()
          .map((e) => PackageScreenTimeModel.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.packageName.isNotEmpty && e.totalTimeMs > 0)
          .toList()
        ..sort((a, b) => b.totalTimeMs.compareTo(a.totalTimeMs));
    } on PlatformException catch (e, st) {
      AppLog.e("getTodayScreenTimeFromEvents failed: ${e.code}", error: e, stackTrace: st);
      return const [];
    }
  }

  Future<DailyUsageModel?> getUsageStats({DateTime? day}) async {
    if (!Platform.isAndroid) return null;
    final targetDay = day ?? DateTime.now();
    final start = _startOfDay(targetDay);
    final end = _endOfQuery(targetDay);
    final payload = await _channel
        .invokeMethod<Map<dynamic, dynamic>>(
      "getUsageStats",
      {
        "startMillis": start.millisecondsSinceEpoch,
        "endMillis": end.millisecondsSinceEpoch,
      },
    )
        .timeout(
      const Duration(seconds: 60),
      onTimeout: () => null,
    );
    if (payload == null) return null;
    return DailyUsageModel.fromMap(
      Map<String, dynamic>.from(payload),
    );
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  /// For today, query only up to now so totals match the system screen-time log.
  DateTime _endOfQuery(DateTime date) {
    final now = DateTime.now();
    if (TodayDate.isSameLocalDay(date)) return now;
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  Future<List<InstalledAppModel>> listInstalledApps() async {
    if (!Platform.isAndroid) return const [];
    try {
      final payload = await _channel
          .invokeMethod<List<dynamic>>("listInstalledApps")
          .timeout(const Duration(seconds: 20), onTimeout: () => const []);
      if (payload == null) return const [];
      return payload
          .whereType<Map>()
          .map((e) => InstalledAppModel.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.packageName.isNotEmpty)
          .toList();
    } on MissingPluginException {
      throw StateError(
        "Installed apps API is not available in the current build. "
        "Please fully stop and run the app again.",
      );
    } on PlatformException catch (e) {
      throw StateError("Could not load installed apps: ${e.message ?? e.code}");
    }
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    if (!Platform.isAndroid || packageName.isEmpty) return null;
    try {
      final payload = await _channel.invokeMethod<Uint8List>(
        "getAppIcon",
        {"packageName": packageName},
      );
      return payload;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
