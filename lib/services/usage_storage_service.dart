import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";

class UsageStorageService {
  static const _boxName = "usage_history_box";

  Future<Box<dynamic>> _openBox() => Hive.openBox<dynamic>(_boxName);

  Future<void> saveDay(DailyUsageModel model) async {
    final box = await _openBox();
    final key = _dayKey(model.date);
    await box.put(key, model.toMap());
  }

  Future<List<DailyUsageModel>> getAllDays() async {
    final box = await _openBox();
    final days = box.values
        .whereType<Map>()
        .map((e) => DailyUsageModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return days;
  }

  Future<DailyUsageModel?> getDay(DateTime day) async {
    final box = await _openBox();
    final map = box.get(_dayKey(day));
    if (map is! Map) return null;
    return DailyUsageModel.fromMap(Map<String, dynamic>.from(map));
  }

  String _dayKey(DateTime date) => "${date.year}-${date.month}-${date.day}";
}
