package com.example.life_pattern_tracker.habits

import com.example.life_pattern_tracker.habits.data.HabitWeeklyProgress

data class HabitDashboardUiState(
    val habits: List<HabitWeeklyProgress> = emptyList(),
) {
    val weeklyCompletionFraction: Float
        get() {
            if (habits.isEmpty()) return 0f
            val totalSlots = habits.size * 7
            val done = habits.sumOf { it.completedDays.coerceIn(0, it.totalDays) }
            return (done.toFloat() / totalSlots.toFloat()).coerceIn(0f, 1f)
        }

    val weeklyCompletionPercent: Int
        get() = (weeklyCompletionFraction * 100f).toInt().coerceIn(0, 100)

    val bestStreakDays: Int
        get() = habits.maxOfOrNull { it.streakDays } ?: 0
}
