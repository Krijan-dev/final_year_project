/// Weekly habit row for dashboard UI.
class WeeklyHabit {
  const WeeklyHabit({
    required this.emoji,
    required this.name,
    required this.completedDays,
    this.totalDays = 7,
    required this.streakDays,
    this.useGradientFill = false,
  });

  final String emoji;
  final String name;
  final int completedDays;
  final int totalDays;
  final int streakDays;
  final bool useGradientFill;

  double get progressFraction =>
      totalDays <= 0 ? 0 : (completedDays / totalDays).clamp(0.0, 1.0);

  static int bestStreakAmong(Iterable<WeeklyHabit> habits) {
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.streakDays).reduce((a, b) => a > b ? a : b);
  }

  static int weeklyCompletionPercent(Iterable<WeeklyHabit> habits) {
    final list = habits.toList();
    if (list.isEmpty) return 0;
    final slots = list.length * 7;
    final done = list.fold<int>(0, (sum, h) => sum + h.completedDays.clamp(0, h.totalDays));
    return ((done / slots) * 100).round().clamp(0, 100);
  }
}
