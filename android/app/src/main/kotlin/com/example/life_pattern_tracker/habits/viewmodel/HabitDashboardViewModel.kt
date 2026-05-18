package com.example.life_pattern_tracker.habits.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.life_pattern_tracker.habits.HabitDashboardUiState
import com.example.life_pattern_tracker.habits.data.HabitWeeklyProgress
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class HabitDashboardViewModel : ViewModel() {

    private val _uiState = MutableStateFlow(HabitDashboardUiState(habits = sampleHabits))
    val uiState: StateFlow<HabitDashboardUiState> = _uiState.asStateFlow()

    private val _lastClickedHabitId = MutableStateFlow<String?>(null)
    val lastClickedHabitId: StateFlow<String?> = _lastClickedHabitId.asStateFlow()

    fun onHabitClick(habit: HabitWeeklyProgress) {
        _lastClickedHabitId.value = habit.id
    }

    /**
     * Demo hook to showcase smooth animated progress transitions (e.g. after syncing data).
     */
    fun applySampleProgressUpdate() {
        viewModelScope.launch {
            _uiState.update { state ->
                state.copy(
                    habits = state.habits.map { habit ->
                        when (habit.id) {
                            "sleep" -> habit.copy(completedDays = (habit.completedDays + 1).coerceAtMost(7))
                            "exercise" -> habit.copy(completedDays = (habit.completedDays + 1).coerceAtMost(7))
                            else -> habit
                        }
                    },
                )
            }
        }
    }

    companion object {
        val sampleHabits: List<HabitWeeklyProgress> = listOf(
            HabitWeeklyProgress(
                id = "sleep",
                emoji = "😴",
                name = "Sleep",
                completedDays = 6,
                streakDays = 12,
                useGradientFill = false,
            ),
            HabitWeeklyProgress(
                id = "exercise",
                emoji = "💪",
                name = "Exercise",
                completedDays = 5,
                streakDays = 4,
                useGradientFill = true,
            ),
            HabitWeeklyProgress(
                id = "water",
                emoji = "💧",
                name = "Water Intake",
                completedDays = 7,
                streakDays = 21,
                useGradientFill = false,
            ),
            HabitWeeklyProgress(
                id = "meditation",
                emoji = "🧘",
                name = "Meditation",
                completedDays = 4,
                streakDays = 2,
                useGradientFill = true,
            ),
        )
    }
}
