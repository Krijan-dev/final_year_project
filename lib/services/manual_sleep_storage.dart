import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";
import "package:life_pattern_tracker/utils/today_date.dart";

/// Local fallback when Health Connect has no sleep (or Sleep permission is off).
abstract final class ManualSleepStorage {
  static const String _keyPrefix = "manual_sleep_hours_";

  static Future<double?> hoursForViewDay([String? dayKey]) async {
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return null;
    final key = dayKey ?? TodayDate.dayKey;
    final raw = Hive.box<dynamic>(kAppSettingsBoxName).get("$_keyPrefix$key");
    if (raw is num && raw > 0) return raw.toDouble();
    return null;
  }

  static Future<void> saveForViewDay(double hours, [String? dayKey]) async {
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return;
    final key = dayKey ?? TodayDate.dayKey;
    await Hive.box<dynamic>(kAppSettingsBoxName).put("$_keyPrefix$key", hours);
  }

  static Future<void> clearForViewDay([String? dayKey]) async {
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return;
    final key = dayKey ?? TodayDate.dayKey;
    await Hive.box<dynamic>(kAppSettingsBoxName).delete("$_keyPrefix$key");
  }
}

/// 0–100 sleep score vs an 8 h goal (used when HC sleep is missing).
abstract final class SleepScore {
  static const double defaultGoalHours = 8.0;

  static int percent(double? hours, {double goalHours = defaultGoalHours}) {
    if (goalHours <= 0) return 0;
    return (((hours ?? 0) / goalHours).clamp(0.0, 1.0) * 100).round();
  }
}
