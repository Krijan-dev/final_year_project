import "dart:io";

import "package:flutter/services.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";

class UsageStatsService {
  static const MethodChannel _channel = MethodChannel("life_pattern_tracker/usage");

  Future<bool> hasUsagePermission() async {
    if (!Platform.isAndroid) return false;
    final result = await _channel.invokeMethod<bool>("hasUsagePermission");
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
}
