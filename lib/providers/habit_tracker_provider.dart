import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/data/mood_types.dart";
import "package:life_pattern_tracker/models/habit_log_preset.dart";
import "package:life_pattern_tracker/models/mood_type.dart";
import "package:life_pattern_tracker/models/habit_tracker_habit.dart";
import "package:life_pattern_tracker/models/mood_day.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";
import "package:life_pattern_tracker/models/today_log_group.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/services/auth_storage_service.dart";
import "package:life_pattern_tracker/services/habit_remote_service.dart";
import "package:life_pattern_tracker/services/habit_tracker_storage_service.dart";
import "package:life_pattern_tracker/utils/habit_log_details_formatter.dart";
import "package:life_pattern_tracker/utils/week_calendar.dart";
import "package:life_pattern_tracker/utils/dev_spoof.dart";

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
  HabitTrackerNotifier(
    this._storage,
    this._authStorage,
    this._habitRemote,
  ) : super(HabitTrackerState.loading()) {
    _load();
  }

  final HabitTrackerStorageService _storage;
  final AuthStorageService _authStorage;
  final HabitRemoteService _habitRemote;

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

    // In spoof mode we always show spoofed weekly data (even if Hive already
    // has older real/spoofed data).
    if (DevSpoof.enabled) {
      state = _spoofWeekState(DevSpoof.level);
      await _persist();
      return;
    }
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
    await _syncToCloud();
  }

  Future<void> _syncToCloud() async {
    if (DevSpoof.enabled) return; // Don't pollute MongoDB while testing UI.
    if (!_habitRemote.isConfigured) return;
    final email = await _authStorage.getSessionEmail();
    if (email == null) return;
    final raw = await _storage.loadRaw();
    if (raw == null) return;
    await _habitRemote.uploadSnapshot(
      userEmail: email,
      weekKey: state.weekKey,
      payload: {
        "weekKey": state.weekKey,
        "habits": raw["habits"] ?? [],
        "moodDays": raw["moodDays"] ?? [],
        "logs": raw["logs"] ?? [],
      },
    );
  }

  static HabitTrackerState _freshWeekState() => HabitTrackerState(
        ready: true,
        weekKey: WeekCalendar.weekKey,
        habits: _defaultHabits(),
        moodDays: _defaultMoodDays(),
        logs: const [],
      );

  static HabitTrackerState _spoofWeekState(DevSpoofLevel level) {
    final labels = WeekCalendar.currentWeekDayLabels();
    // Completion patterns so weekly progress isn't always 0/100.
    List<bool> completedFor(String habitId) {
      switch (level) {
        case DevSpoofLevel.best:
          return switch (habitId) {
            "sleep" => <bool>[false, false, true, true, false, false, true],
            "exercise" => <bool>[false, true, false, true, true, false, false],
            "water" => <bool>[true, true, false, false, true, true, false],
            "read" => <bool>[false, false, true, false, false, false, true],
            "meditate" => <bool>[true, false, true, false, true, false, false],
            "mood" => <bool>[false, true, true, false, false, true, true],
            _ => <bool>[false, false, false, false, false, false, false],
          };
        case DevSpoofLevel.medium:
          return switch (habitId) {
            "sleep" => <bool>[false, true, false, true, false, true, false],
            "exercise" => <bool>[false, false, true, false, true, false, false],
            "water" => <bool>[true, false, true, false, true, false, true],
            "read" => <bool>[false, false, false, true, false, false, true],
            "meditate" => <bool>[true, false, false, true, false, true, false],
            "mood" => <bool>[false, true, false, false, true, false, true],
            _ => <bool>[false, false, false, false, false, false, false],
          };
        case DevSpoofLevel.bad:
          return switch (habitId) {
            "sleep" => <bool>[false, false, false, true, false, false, false],
            "exercise" => <bool>[false, false, false, false, true, false, false],
            "water" => <bool>[false, true, false, false, false, false, true],
            "read" => <bool>[false, false, false, false, false, false, true],
            "meditate" => <bool>[false, false, true, false, false, false, false],
            "mood" => <bool>[false, false, false, true, false, false, false],
            _ => <bool>[false, false, false, false, false, false, false],
          };
        case DevSpoofLevel.off:
          return <bool>[false, false, false, false, false, false, false];
      }
    }

    final habits = _defaultHabits().map((h) {
      return HabitTrackerHabit(
        id: h.id,
        name: h.name,
        emoji: h.emoji,
        iconBackground: h.iconBackground,
        weekCompleted: completedFor(h.id),
      );
    }).toList();

    final moodScores = switch (level) {
      DevSpoofLevel.best => <double>[9, 8, 9, 7, 6, 8, 9],
      DevSpoofLevel.medium => <double>[7, 6, 7, 6, 5, 6, 7],
      DevSpoofLevel.bad => <double>[4, 3, 5, 4, 2, 3, 4],
      DevSpoofLevel.off => <double>[0, 0, 0, 0, 0, 0, 0],
    };
    MoodDay moodDayFor(int i) {
      final score = moodScores[i].clamp(0.0, 10.0);
      final typeId = switch (score) {
        >= 9 => "great",
        >= 8 => "good",
        >= 7 => "calm",
        >= 6 => "okay",
        >= 5 => "tired",
        >= 4 => "stressed",
        >= 3 => "sad",
        _ => "angry",
      };
      final type = MoodTypes.byId(typeId) ?? MoodTypes.all.first;
      return MoodDay(
        label: labels[i],
        emoji: type.emoji,
        score: score,
        moodTypeId: type.id,
        moodTypeLabel: type.label,
      );
    }

    final moodDays = List<MoodDay>.generate(
      7,
      (i) => moodDayFor(i),
    );

    final ms = DateTime.now().millisecondsSinceEpoch.toString();
    final logs = switch (level) {
      DevSpoofLevel.best => <TodayLogEntry>[
          TodayLogEntry(
            id: "spoof-$ms-meditation",
            activityKey: "meditation",
            emoji: "🧘",
            title: "Meditation",
            subtitle: "15 min",
            timeLabel: "07:20 AM",
            dateKey: WeekCalendar.todayKey,
          ),
          TodayLogEntry(
            id: "spoof-$ms-water",
            activityKey: "water",
            emoji: "💧",
            title: "Drink Water",
            subtitle: "250 ml",
            timeLabel: "10:15 AM",
            dateKey: WeekCalendar.todayKey,
          ),
          TodayLogEntry(
            id: "spoof-$ms-workout",
            activityKey: "workout",
            emoji: "💪",
            title: "Workout",
            subtitle: "30 min",
            timeLabel: "06:00 PM",
            dateKey: WeekCalendar.todayKey,
          ),
          TodayLogEntry(
            id: "spoof-$ms-mood",
            activityKey: "mood",
            emoji: "😊",
            title: "Mood Check",
            subtitle: "Checked in",
            timeLabel: "09:30 PM",
            dateKey: WeekCalendar.todayKey,
          ),
        ],
      DevSpoofLevel.medium => <TodayLogEntry>[
          TodayLogEntry(
            id: "spoof-$ms-water",
            activityKey: "water",
            emoji: "💧",
            title: "Drink Water",
            subtitle: "200 ml",
            timeLabel: "11:10 AM",
            dateKey: WeekCalendar.todayKey,
          ),
          TodayLogEntry(
            id: "spoof-$ms-mood",
            activityKey: "mood",
            emoji: "🙂",
            title: "Mood Check",
            subtitle: "Okay day",
            timeLabel: "08:45 PM",
            dateKey: WeekCalendar.todayKey,
          ),
        ],
      DevSpoofLevel.bad => <TodayLogEntry>[
          TodayLogEntry(
            id: "spoof-$ms-mood",
            activityKey: "mood",
            emoji: "😔",
            title: "Mood Check",
            subtitle: "Low energy",
            timeLabel: "09:00 PM",
            dateKey: WeekCalendar.todayKey,
          ),
        ],
      DevSpoofLevel.off => <TodayLogEntry>[],
    };

    return HabitTrackerState(
      ready: true,
      weekKey: WeekCalendar.weekKey,
      habits: habits,
      moodDays: moodDays,
      logs: logs,
    );
  }

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

  static String? mapLogKeyToHabitId(String activityKey) {
    final mapped = _logToHabitId[activityKey];
    if (mapped != null) return mapped;
    // Allow callers to pass direct habit IDs as log keys.
    if (activityKey == "sleep" ||
        activityKey == "exercise" ||
        activityKey == "water" ||
        activityKey == "read" ||
        activityKey == "meditate" ||
        activityKey == "mood") {
      return activityKey;
    }
    return null;
  }

  void addLogSession({
    required String activityKey,
    required String title,
    required String subtitle,
    required String emoji,
    required String timeLabel,
    required HabitLogAmountUnit amountUnit,
    String? dateKey,
  }) {
    final targetDateKey = dateKey ?? WeekCalendar.todayKey;
    final formatted = HabitLogDetailsFormatter.format(subtitle, amountUnit);
    final entry = TodayLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityKey: activityKey,
      emoji: emoji,
      title: title,
      subtitle: formatted.isEmpty ? "Logged" : formatted,
      timeLabel: timeLabel,
      dateKey: targetDateKey,
    );
    state = state.copyWith(logs: [...state.logs, entry]);
    _markHabitFromLog(activityKey, targetDateKey);
    _persist();
  }

  void addLogSessionFromPreset({
    required HabitLogPreset preset,
    required String timeLabel,
    required String subtitle,
    String? dateKey,
  }) {
    addLogSession(
      activityKey: preset.id,
      title: preset.title,
      subtitle: subtitle,
      emoji: preset.emoji,
      timeLabel: timeLabel,
      amountUnit: preset.amountUnit,
      dateKey: dateKey,
    );
  }

  void _markHabitFromLog(String activityKey, String dateKey) {
    final habitId = mapLogKeyToHabitId(activityKey);
    if (habitId == null) return;
    final dayIndex = WeekCalendar.weekIndexForDateKey(dateKey);
    if (dayIndex < 0 || dayIndex > 6) return;
    final updated = state.habits.map((h) {
      if (h.id != habitId) return h;
      final days = List<bool>.from(h.weekCompleted);
      days[dayIndex] = true;
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
    // Rebuild weekly checks from all current-week logs (supports backdated entries).
    for (final log in state.logs) {
      _markHabitFromLog(log.activityKey, log.dateKey);
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

final habitRemoteServiceProvider = Provider<HabitRemoteService>((ref) => HabitRemoteService());

final habitTrackerProvider =
    StateNotifierProvider<HabitTrackerNotifier, HabitTrackerState>((ref) {
  return HabitTrackerNotifier(
    ref.read(habitTrackerStorageProvider),
    ref.read(authStorageServiceProvider),
    ref.read(habitRemoteServiceProvider),
  );
});
