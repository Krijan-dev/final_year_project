import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/models/app_screen_time_limit.dart";

/// Hive persistence for per-app daily limits and one-shot notification ledger.
class AppScreenTimeLimitStorage {
  static const _boxName = "screen_time_limits_box";
  static const _limitsKey = "limits_v1";
  static const _notifiedPrefix = "notified_";

  Future<Box<dynamic>> _openBox() => Hive.openBox<dynamic>(_boxName);

  Future<Map<String, AppScreenTimeLimit>> loadAll() async {
    final box = await _openBox();
    final raw = box.get(_limitsKey);
    if (raw is! Map) return {};
    final out = <String, AppScreenTimeLimit>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is! Map) continue;
      final m = Map<String, dynamic>.from(v);
      final limit = AppScreenTimeLimit.fromMap(m);
      if (limit.packageName.isNotEmpty) {
        out[limit.packageName] = limit;
      }
    }
    return out;
  }

  Future<void> save(AppScreenTimeLimit limit) async {
    final box = await _openBox();
    final all = await loadAll();
    all[limit.packageName] = limit;
    await box.put(
      _limitsKey,
      {for (final e in all.entries) e.key: e.value.toMap()},
    );
  }

  Future<void> remove(String packageName) async {
    final box = await _openBox();
    final all = await loadAll();
    all.remove(packageName);
    await box.put(
      _limitsKey,
      {for (final e in all.entries) e.key: e.value.toMap()},
    );
    await _clearNotifiedForPackage(box, packageName);
  }

  Future<void> _clearNotifiedForPackage(Box<dynamic> box, String packageName) async {
    final keys = box.keys.whereType<String>().where(
          (k) => k.startsWith("${_notifiedPrefix}${packageName}_"),
        );
    for (final k in keys) {
      await box.delete(k);
    }
  }

  String _dayKey(DateTime d) => "${d.year}-${d.month}-${d.day}";

  String _notifiedKey(String packageName, DateTime day) =>
      "$_notifiedPrefix${packageName}_${_dayKey(day)}";

  Future<bool> wasNotifiedToday(String packageName, DateTime day) async {
    final box = await _openBox();
    return box.get(_notifiedKey(packageName, day)) == true;
  }

  Future<void> markNotifiedToday(String packageName, DateTime day) async {
    final box = await _openBox();
    await box.put(_notifiedKey(packageName, day), true);
  }
}
