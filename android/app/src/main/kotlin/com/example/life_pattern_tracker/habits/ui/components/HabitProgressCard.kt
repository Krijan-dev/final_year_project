package com.example.life_pattern_tracker.habits.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.life_pattern_tracker.habits.data.HabitWeeklyProgress
import com.example.life_pattern_tracker.habits.ui.theme.HabitsTheme
import com.example.life_pattern_tracker.habits.viewmodel.HabitDashboardViewModel

@Preview(showBackground = true, name = "Habit row · Light")
@Composable
private fun HabitProgressCardPreviewLight() {
    HabitsTheme(darkTheme = false, dynamicColor = false) {
        HabitProgressCard(
            habit = HabitDashboardViewModel.sampleHabits.first(),
            onClick = {},
            modifier = Modifier.padding(16.dp),
        )
    }
}

@Preview(showBackground = true, name = "Habit row · Dark")
@Composable
private fun HabitProgressCardPreviewDark() {
    HabitsTheme(darkTheme = true, dynamicColor = false) {
        HabitProgressCard(
            habit = HabitWeeklyProgress(
                id = "reading",
                emoji = "📚",
                name = "Reading",
                completedDays = 3,
                streakDays = 6,
                useGradientFill = true,
            ),
            onClick = {},
            modifier = Modifier.padding(16.dp),
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HabitProgressCard(
    habit: HabitWeeklyProgress,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Card(
        onClick = onClick,
        modifier = modifier.fillMaxWidth(),
        shape = MaterialTheme.shapes.large,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = habit.emoji,
                    style = MaterialTheme.typography.titleLarge,
                )
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = habit.name,
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
                Text(
                    text = "${habit.completedDays}/${habit.totalDays} days",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            AnimatedHabitProgressBar(
                progress = habit.progressFraction,
                useGradient = habit.useGradientFill,
                modifier = Modifier.fillMaxWidth(),
            )

            if (habit.streakDays > 0) {
                Text(
                    text = "Streak ${habit.streakDays} days",
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.primary,
                )
            }
        }
    }
}
