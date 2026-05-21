import "package:flutter/material.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/models/habit_tracker_habit.dart";
import "package:life_pattern_tracker/models/mood_day.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";
import "package:life_pattern_tracker/utils/week_calendar.dart";

class HabitTrackerStorageService {
  static const _boxName = "habit_tracker_box";
  static const _stateKey = "state_v1";

  Future<Box<dynamic>> _openBox() => Hive.openBox<dynamic>(_boxName);

  Future<Map<String, dynamic>?> loadRaw() async {
    final box = await _openBox();
    final raw = box.get(_stateKey);
    if (raw is! Map) return null;
    return Map<String, dynamic>.from(raw);
  }

  Future<void> save({
    required String weekKey,
    required List<HabitTrackerHabit> habits,
    required List<MoodDay> moodDays,
    required List<TodayLogEntry> logs,
  }) async {
    final box = await _openBox();
    await box.put(_stateKey, {
      "weekKey": weekKey,
      "habits": habits.map(_habitToMap).toList(),
      "moodDays": moodDays.map(_moodToMap).toList(),
      "logs": logs.map(_logToMap).toList(),
    });
  }

  static Map<String, dynamic> _habitToMap(HabitTrackerHabit h) => {
        "id": h.id,
        "name": h.name,
        "emoji": h.emoji,
        "iconBackground": h.iconBackground.toARGB32(),
        "weekCompleted": h.weekCompleted,
      };

  static HabitTrackerHabit _habitFromMap(Map<String, dynamic> m) {
    final completed = (m["weekCompleted"] as List?)?.cast<bool>() ?? List.filled(7, false);
    final padded = List<bool>.from(completed);
    while (padded.length < 7) {
      padded.add(false);
    }
    if (padded.length > 7) padded.removeRange(7, padded.length);
    return HabitTrackerHabit(
      id: m["id"] as String? ?? "",
      name: m["name"] as String? ?? "Habit",
      emoji: m["emoji"] as String? ?? "✅",
      iconBackground: Color(m["iconBackground"] as int? ?? 0xFFDCFCE7),
      weekCompleted: padded,
    );
  }

  static Map<String, dynamic> _moodToMap(MoodDay d) => {
        "label": d.label,
        "emoji": d.emoji,
        "score": d.score,
        if (d.moodTypeId != null) "moodTypeId": d.moodTypeId,
        if (d.moodTypeLabel != null) "moodTypeLabel": d.moodTypeLabel,
      };

  static MoodDay _moodFromMap(Map<String, dynamic> m) => MoodDay(
        label: m["label"] as String? ?? "",
        emoji: m["emoji"] as String? ?? "😐",
        score: (m["score"] as num?)?.toDouble() ?? 0,
        moodTypeId: m["moodTypeId"] as String?,
        moodTypeLabel: m["moodTypeLabel"] as String?,
      );

  static Map<String, dynamic> _logToMap(TodayLogEntry e) => {
        "id": e.id,
        "activityKey": e.activityKey,
        "emoji": e.emoji,
        "title": e.title,
        "subtitle": e.subtitle,
        "timeLabel": e.timeLabel,
        "dateKey": e.dateKey,
      };

  static TodayLogEntry _logFromMap(Map<String, dynamic> m) => TodayLogEntry(
        id: m["id"] as String? ?? "",
        activityKey: m["activityKey"] as String? ?? "",
        emoji: m["emoji"] as String? ?? "✅",
        title: m["title"] as String? ?? "",
        subtitle: m["subtitle"] as String? ?? "Logged",
        timeLabel: m["timeLabel"] as String? ?? "",
        dateKey: m["dateKey"] as String? ?? WeekCalendar.todayKey,
      );

  static List<HabitTrackerHabit> parseHabits(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((e) => _habitFromMap(Map<String, dynamic>.from(e)))
        .where((h) => h.id.isNotEmpty)
        .toList();
  }

  static List<MoodDay> parseMoodDays(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((e) => _moodFromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<TodayLogEntry> parseLogs(List<dynamic>? list) {
    if (list == null) return [];
    return list
        .whereType<Map>()
        .map((e) => _logFromMap(Map<String, dynamic>.from(e)))
        .where((e) => e.id.isNotEmpty)
        .toList();
  }
}
