import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/habit_tracker_habit.dart";
import "package:life_pattern_tracker/models/mood_day.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";

class HabitTrackerState {
  const HabitTrackerState({
    required this.habits,
    required this.moodDays,
    required this.logs,
  });

  final List<HabitTrackerHabit> habits;
  final List<MoodDay> moodDays;
  final List<TodayLogEntry> logs;

  int get weeklyProgressPercent {
    if (habits.isEmpty) return 0;
    final slots = habits.length * 7;
    final done = habits.fold<int>(0, (s, h) => s + h.completedDays);
    return ((done / slots) * 100).round().clamp(0, 100);
  }

  double get averageMood {
    if (moodDays.isEmpty) return 0;
    final sum = moodDays.fold<double>(0, (s, d) => s + d.score);
    return sum / moodDays.length;
  }

  HabitTrackerState copyWith({
    List<HabitTrackerHabit>? habits,
    List<MoodDay>? moodDays,
    List<TodayLogEntry>? logs,
  }) {
    return HabitTrackerState(
      habits: habits ?? this.habits,
      moodDays: moodDays ?? this.moodDays,
      logs: logs ?? this.logs,
    );
  }
}

class HabitTrackerNotifier extends StateNotifier<HabitTrackerState> {
  HabitTrackerNotifier() : super(_initial);

  static final HabitTrackerState _initial = HabitTrackerState(
    habits: _sampleHabits,
    moodDays: _sampleMood,
    logs: _sampleLogs,
  );

  static final List<HabitTrackerHabit> _sampleHabits = [
    HabitTrackerHabit(
      id: "sleep",
      name: "Sleep 8 hours",
      emoji: "🌙",
      iconBackground: Color(0xFFEDE9FE),
      weekCompleted: [true, true, false, true, true, true, false],
    ),
    HabitTrackerHabit(
      id: "exercise",
      name: "Exercise",
      emoji: "💪",
      iconBackground: Color(0xFFFCE7F3),
      weekCompleted: [true, false, true, true, true, false, false],
    ),
    HabitTrackerHabit(
      id: "water",
      name: "Drink Water",
      emoji: "💧",
      iconBackground: Color(0xFFDBEAFE),
      weekCompleted: [true, true, true, true, true, true, true],
    ),
    HabitTrackerHabit(
      id: "read",
      name: "Read",
      emoji: "📖",
      iconBackground: Color(0xFFFFEDD5),
      weekCompleted: [false, true, true, false, true, true, false],
    ),
    HabitTrackerHabit(
      id: "meditate",
      name: "Meditate",
      emoji: "🧘",
      iconBackground: Color(0xFFF3E8FF),
      weekCompleted: [true, true, false, false, true, true, false],
    ),
    HabitTrackerHabit(
      id: "mood",
      name: "Mood Check",
      emoji: "😊",
      iconBackground: Color(0xFFFCE7F3),
      weekCompleted: [true, true, true, true, true, true, false],
    ),
  ];

  static const List<MoodDay> _sampleMood = [
    MoodDay(label: "Mon", emoji: "😊", score: 8.5),
    MoodDay(label: "Tue", emoji: "😄", score: 9.0),
    MoodDay(label: "Wed", emoji: "🙂", score: 7.5),
    MoodDay(label: "Thu", emoji: "😊", score: 8.0),
    MoodDay(label: "Fri", emoji: "😁", score: 9.5),
    MoodDay(label: "Sat", emoji: "😊", score: 8.0),
    MoodDay(label: "Sun", emoji: "😐", score: 6.0),
  ];

  static const List<TodayLogEntry> _sampleLogs = [
    TodayLogEntry(
      id: "1",
      emoji: "🧘",
      title: "Morning Meditation",
      subtitle: "15 min",
      timeLabel: "07:00 AM",
    ),
    TodayLogEntry(
      id: "2",
      emoji: "💧",
      title: "Breakfast",
      subtitle: "Water x2",
      timeLabel: "08:00 AM",
    ),
    TodayLogEntry(
      id: "3",
      emoji: "💪",
      title: "Workout",
      subtitle: "45 min",
      timeLabel: "09:30 AM",
    ),
    TodayLogEntry(
      id: "4",
      emoji: "📚",
      title: "Reading",
      subtitle: "30 min",
      timeLabel: "02:00 PM",
    ),
  ];

  void toggleHabitDay(String habitId, int dayIndex) {
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
  }

  void addLog({required String title, required String subtitle, required String emoji}) {
    final entry = TodayLogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emoji: emoji,
      title: title,
      subtitle: subtitle,
      timeLabel: _formatNow(),
    );
    state = state.copyWith(logs: [...state.logs, entry]);
  }

  static String _formatNow() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final m = now.minute.toString().padLeft(2, "0");
    final period = now.hour >= 12 ? "PM" : "AM";
    return "$h:$m $period";
  }

  Future<void> refresh() async {
    state = _initial;
  }
}

final habitTrackerProvider =
    StateNotifierProvider<HabitTrackerNotifier, HabitTrackerState>((ref) {
  return HabitTrackerNotifier();
});
