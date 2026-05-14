package com.example.life_pattern_tracker.habits.data

/**
 * Represents one habit's progress for the current week.
 *
 * @param useGradientFill When true, the progress bar uses a horizontal gradient instead of solid navy.
 */
data class HabitWeeklyProgress(
    val id: String,
    val emoji: String,
    val name: String,
    val completedDays: Int,
    val totalDays: Int = 7,
    val streakDays: Int,
    val useGradientFill: Boolean = false,
) {
    val progressFraction: Float
        get() = if (totalDays <= 0) 0f else (completedDays.toFloat() / totalDays.toFloat()).coerceIn(0f, 1f)
}
