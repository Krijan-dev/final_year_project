import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/data/mood_types.dart";
import "package:life_pattern_tracker/models/habit_log_preset.dart";
import "package:life_pattern_tracker/models/mood_type.dart";
import "package:life_pattern_tracker/models/habit_tracker_habit.dart";
import "package:life_pattern_tracker/models/mood_day.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";
import "package:life_pattern_tracker/models/today_log_group.dart";
import "package:life_pattern_tracker/services/habit_tracker_storage_service.dart";
import "package:life_pattern_tracker/utils/habit_log_details_formatter.dart";
import "package:life_pattern_tracker/utils/week_calendar.dart";

class HabitTrackerState {
  const HabitTrackerState({
    required this.ready,
    required this.weekKey,
    required this.habits,
    required this.moodDays,
    required this.logs,
  });

  final bool ready;
  final String weekKey;
  final List<HabitTrackerHabit> habits;
  final List<MoodDay> moodDays;
  final List<TodayLogEntry> logs;

  List<TodayLogEntry> get todayLogs =>
      logs.where((e) => e.dateKey == WeekCalendar.todayKey).toList();

  int get weeklyProgressPercent {
    if (habits.isEmpty) return 0;
    final slots = habits.length * 7;
    final done = habits.fold<int>(0, (s, h) => s + h.completedDays);
    return ((done / slots) * 100).round().clamp(0, 100);
  }

  double get averageMood {
    final scored = moodDays.where((d) => d.score > 0);
    if (scored.isEmpty) return 0;
    return scored.fold<double>(0, (s, d) => s + d.score) / scored.length;
  }

  int get bestStreakDays {
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.currentStreak()).reduce((a, b) => a > b ? a : b);
  }

  String get weeklyProgressMessage {
    final p = weeklyProgressPercent;
    if (p == 0) return "Mark habits or log activities to get started.";
    if (p < 40) return "Good start — keep building momentum.";
    if (p < 70) return "You're making steady progress this week.";
    if (p < 100) return "Almost there — strong week so far!";
    return "Perfect week — outstanding consistency!";
  }

  HabitTrackerState copyWith({
    bool? ready,
    String? weekKey,
    List<HabitTrackerHabit>? habits,
    List<MoodDay>? moodDays,
    List<TodayLogEntry>? logs,
  }) {
    return HabitTrackerState(
      ready: ready ?? this.ready,
      weekKey: weekKey ?? this.weekKey,
      habits: habits ?? this.habits,
      moodDays: moodDays ?? this.moodDays,
      logs: logs ?? this.logs,
    );
  }

  static HabitTrackerState loading() => HabitTrackerState(
        ready: false,
        weekKey: WeekCalendar.weekKey,
        habits: const [],
        moodDays: const [],
        logs: const [],
      );
}

class HabitTrackerNotifier extends StateNotifier<HabitTrackerState> {
  HabitTrackerNotifier(this._storage) : super(HabitTrackerState.loading()) {
    _load();
  }

  final HabitTrackerStorageService _storage;

  static const Map<String, String> _logToHabitId = {
    "meditation": "meditate",
    "workout": "exercise",
    "water": "water",
    "read": "read",
    "sleep": "sleep",
    "mood": "mood",
  };

  Future<void> _load() async {
    final raw = await _storage.loadRaw();
    final currentWeek = WeekCalendar.weekKey;
    if (raw == null) {
      state = _freshWeekState();
      await _persist();
      return;
    }

    final savedWeek = raw["weekKey"] as String? ?? "";
    var habits = HabitTrackerStorageService.parseHabits(raw["habits"] as List?);
    var moodDays = HabitTrackerStorageService.parseMoodDays(raw["moodDays"] as List?);
    final logs = HabitTrackerStorageService.parseLogs(raw["logs"] as List?);

    if (savedWeek != currentWeek) {
      habits = _resetHabitsForNewWeek(habits);
      moodDays = _defaultMoodDays();
    } else {
      habits = habits.isEmpty ? _defaultHabits() : habits;
      moodDays = _normalizeMoodDays(moodDays);
    }

    state = HabitTrackerState(
      ready: true,
      weekKey: currentWeek,
      habits: habits,
      moodDays: moodDays,
      logs: logs,
    );
    _applyTodayLogsToHabits();
  }

  Future<void> _persist() async {
    await _storage.save(
      weekKey: state.weekKey,
      habits: state.habits,
      moodDays: state.moodDays,
      logs: state.logs,
    );
  }

  static HabitTrackerState _freshWeekState() => HabitTrackerState(
        ready: true,
        weekKey: WeekCalendar.weekKey,
        habits: _defaultHabits(),
        moodDays: _defaultMoodDays(),
        logs: const [],
      );

  static List<HabitTrackerHabit> _defaultHabits() => [
        HabitTrackerHabit(
          id: "sleep",
          name: "Sleep 8 hours",
          emoji: "🌙",
          iconBackground: const Color(0xFFEDE9FE),
          weekCompleted: List.filled(7, false),
        ),
        HabitTrackerHabit(
          id: "exercise",
          name: "Exercise",
          emoji: "💪",
          iconBackground: const Color(0xFFFCE7F3),
          weekCompleted: List.filled(7, false),
        ),
        HabitTrackerHabit(
          id: "water",
          name: "Drink Water",
          emoji: "💧",
          iconBackground: const Color(0xFFDBEAFE),
          weekCompleted: List.filled(7, false),
        ),
        HabitTrackerHabit(
          id: "read",
          name: "Read",
          emoji: "📖",
          iconBackground: const Color(0xFFFFEDD5),
          weekCompleted: List.filled(7, false),
        ),
        HabitTrackerHabit(
          id: "meditate",
          name: "Meditate",
          emoji: "🧘",
          iconBackground: const Color(0xFFF3E8FF),
          weekCompleted: List.filled(7, false),
        ),
        HabitTrackerHabit(
          id: "mood",
          name: "Mood Check",
          emoji: "😊",
          iconBackground: const Color(0xFFFCE7F3),
          weekCompleted: List.filled(7, false),
        ),
      ];

  static List<HabitTrackerHabit> _resetHabitsForNewWeek(List<HabitTrackerHabit> prior) {
    final template = prior.isEmpty ? _defaultHabits() : prior;
    return template
        .map(
          (h) => HabitTrackerHabit(
            id: h.id,
            name: h.name,
            emoji: h.emoji,
            iconBackground: h.iconBackground,
            weekCompleted: List.filled(7, false),
          ),
        )
        .toList();
  }

  static MoodDay _migrateLegacyMood(MoodDay day) {
    if (day.score <= 0 || day.moodTypeId != null) return day;
    MoodType? closest;
    var bestDiff = double.infinity;
    for (final type in MoodTypes.all) {
      final diff = (type.defaultScore - day.score).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        closest = type;
      }
    }
    if (closest == null) return day;
    return MoodDay(
      label: day.label,
      emoji: closest.emoji,
      score: day.score,
      moodTypeId: closest.id,
      moodTypeLabel: closest.label,
    );
  }

  static List<MoodDay> _defaultMoodDays() {
    final labels = WeekCalendar.currentWeekDayLabels();
    return List.generate(
      labels.length,
      (i) => MoodDay(label: labels[i], emoji: "—", score: 0),
    );
  }

  static List<MoodDay> _normalizeMoodDays(List<MoodDay> days) {
    final labels = WeekCalendar.currentWeekDayLabels();
    if (days.length == 7) {
      return List.generate(
        7,
        (i) => _migrateLegacyMood(
          MoodDay(
            label: labels[i],
            emoji: days[i].emoji,
            score: days[i].score,
            moodTypeId: days[i].moodTypeId,
            moodTypeLabel: days[i].moodTypeLabel,
          ),
        ),
      );
    }
    return _defaultMoodDays();
  }

  static String moodEmojiForScore(double score) {
    if (score >= 9) return "😁";
    if (score >= 8) return "😄";
    if (score >= 7) return "😊";
    if (score >= 6) return "🙂";
    if (score >= 4) return "😐";
    if (score > 0) return "😔";
    return "—";
  }

  void toggleHabitDay(String habitId, int dayIndex) {
    if (dayIndex < 0 || dayIndex > 6) return;
    final updated = state.habits.map((h) {
      if (h.id != habitId) return h;
      final days = List<bool>.from(h.weekCompleted);
      days[dayIndex] = !days[dayIndex];
      return HabitTrackerHabit(
        id: h.id,
        name: h.name,
        emoji: h.emoji,
        iconBackground: h.iconBackground,
        weekCompleted: days,
      );
    }).toList();
    state = state.copyWith(habits: updated);
    _persist();
  }

  void setMood({
    required int dayIndex,
    required String moodTypeId,
    double? score,
  }) {
    if (dayIndex < 0 || dayIndex > 6) return;
    if (dayIndex > WeekCalendar.todayWeekIndex) return;
    final type = MoodTypes.byId(moodTypeId);
    if (type == null) return;

    final clamped = (score ?? type.defaultScore).clamp(1.0, 10.0);
    final updated = List<MoodDay>.from(state.moodDays);
    updated[dayIndex] = MoodDay(
      label: updated[dayIndex].label,
      emoji: type.emoji,
      score: clamped,
      moodTypeId: type.id,
      moodTypeLabel: type.label,
    );
    state = state.copyWith(moodDays: updated);
    _syncMoodHabitCheck(dayIndex, true);
    _persist();
  }

  void _syncMoodHabitCheck(int dayIndex, bool done) {
    final updated = state.habits.map((h) {
      if (h.id != "mood") return h;
      final days = List<bool>.from(h.weekCompleted);
      days[dayIndex] = done;
      return HabitTrackerHabit(
        id: h.id,
        name: h.name,
        emoji: h.emoji,
        iconBackground: h.iconBackground,
        weekCompleted: days,
      );
    }).toList();
    state = state.copyWith(habits: updated);
  }

  List<TodayLogEntry> sessionsForActivityKey(String activityKey) {
    return state.todayLogs.where((e) => e.activityKey == activityKey).toList();
  }

  static List<TodayLogGroup> groupLogs(List<TodayLogEntry> logs) {
    final orderedKeys = <String>[];
    final map = <String, List<TodayLogEntry>>{};
    for (final log in logs) {
      if (!map.containsKey(log.activityKey)) {
        orderedKeys.add(log.activityKey);
      }
      map.putIfAbsent(log.activityKey, () => []).add(log);
    }
    return [
      for (final key in orderedKeys)
        TodayLogGroup(
          activityKey: key,
          title: map[key]!.first.title,
          emoji: map[key]!.first.emoji,
          amountUnit: HabitLogDetailsFormatter.unitForActivityKey(
            key,
            map[key]!.first.title,
          ),
          sessions: map[key]!,
        ),
    ];
  }

  static String customActivityKey(String title) {
    final normalized = title.trim().toLowerCase().replaceAll(RegExp(r"\s+"), "_");
    return "custom:$normalized";
  }

  void addLogSession({
    required String activityKey,
    required String title,
    required String subtitle,
    required String emoji,
    required String timeLabel,
    required HabitLogAmountUnit amountUnit,
  }) {
    final formatted = HabitLogDetailsFormatter.format(subtitle, amountUnit);
    final entry = TodayLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityKey: activityKey,
      emoji: emoji,
      title: title,
      subtitle: formatted.isEmpty ? "Logged" : formatted,
      timeLabel: timeLabel,
      dateKey: WeekCalendar.todayKey,
    );
    state = state.copyWith(logs: [...state.logs, entry]);
    _markHabitFromLog(activityKey);
    _persist();
  }

  void addLogSessionFromPreset({
    required HabitLogPreset preset,
    required String timeLabel,
    required String subtitle,
  }) {
    addLogSession(
      activityKey: preset.id,
      title: preset.title,
      subtitle: subtitle,
      emoji: preset.emoji,
      timeLabel: timeLabel,
      amountUnit: preset.amountUnit,
    );
  }

  void _markHabitFromLog(String activityKey) {
    final habitId = _logToHabitId[activityKey];
    if (habitId == null) return;
    final today = WeekCalendar.todayWeekIndex;
    final updated = state.habits.map((h) {
      if (h.id != habitId) return h;
      final days = List<bool>.from(h.weekCompleted);
      days[today] = true;
      return HabitTrackerHabit(
        id: h.id,
        name: h.name,
        emoji: h.emoji,
        iconBackground: h.iconBackground,
        weekCompleted: days,
      );
    }).toList();
    state = state.copyWith(habits: updated);
  }

  void _applyTodayLogsToHabits() {
    for (final log in state.todayLogs) {
      _markHabitFromLog(log.activityKey);
    }
  }

  Future<void> refresh() async {
    state = HabitTrackerState.loading();
    await _load();
  }
}

final habitTrackerStorageProvider = Provider<HabitTrackerStorageService>((ref) {
  return HabitTrackerStorageService();
});

final habitTrackerProvider =
    StateNotifierProvider<HabitTrackerNotifier, HabitTrackerState>((ref) {
  return HabitTrackerNotifier(ref.read(habitTrackerStorageProvider));
});
