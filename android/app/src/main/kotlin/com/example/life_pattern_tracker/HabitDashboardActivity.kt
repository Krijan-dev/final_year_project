package com.example.life_pattern_tracker

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.example.life_pattern_tracker.habits.ui.screen.HabitDashboardScreen
import com.example.life_pattern_tracker.habits.ui.theme.HabitsTheme

/**
 * Native Compose dashboard for weekly habit progress.
 *
 * Launch for UI review without changing the Flutter entrypoint:
 * `adb shell am start -n com.example.life_pattern_tracker/.HabitDashboardActivity`
 */
class HabitDashboardActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            HabitsTheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    HabitDashboardScreen()
                }
            }
        }
    }
}
