import "dart:io";

import "package:flutter/services.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/models/installed_app_model.dart";

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

  Future<DailyUsageModel?> getUsageStats({DateTime? day}) async {
    if (!Platform.isAndroid) return null;
    final payload = await _channel
        .invokeMethod<Map<dynamic, dynamic>>(
      "getUsageStats",
      {
        "startMillis": _startOfDay(day ?? DateTime.now()).millisecondsSinceEpoch,
        "endMillis": _endOfDay(day ?? DateTime.now()).millisecondsSinceEpoch,
      },
    )
        .timeout(
      const Duration(seconds: 45),
      onTimeout: () => null,
    );
    if (payload == null) return null;
    return DailyUsageModel.fromMap(
      Map<String, dynamic>.from(payload),
    );
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

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
