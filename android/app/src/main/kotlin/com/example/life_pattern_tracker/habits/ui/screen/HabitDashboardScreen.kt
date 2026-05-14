package com.example.life_pattern_tracker.habits.ui.screen

import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SmallFloatingActionButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.life_pattern_tracker.habits.HabitDashboardUiState
import com.example.life_pattern_tracker.habits.data.HabitWeeklyProgress
import com.example.life_pattern_tracker.habits.ui.components.HabitProgressCard
import com.example.life_pattern_tracker.habits.ui.theme.HabitsTheme
import com.example.life_pattern_tracker.habits.viewmodel.HabitDashboardViewModel
import kotlinx.coroutines.delay

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HabitDashboardScreen(
    viewModel: HabitDashboardViewModel = viewModel(),
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    HabitDashboardContent(
        uiState = uiState,
        onHabitClick = viewModel::onHabitClick,
        onDemoProgressBump = viewModel::applySampleProgressUpdate,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HabitDashboardContent(
    uiState: HabitDashboardUiState,
    onHabitClick: (HabitWeeklyProgress) -> Unit,
    onDemoProgressBump: () -> Unit,
) {
    var showEnterAnimation by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(40)
        showEnterAnimation = true
    }

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Dashboard",
                        style = MaterialTheme.typography.titleLarge,
                    )
                },
            )
        },
        floatingActionButton = {
            SmallFloatingActionButton(onClick = onDemoProgressBump) {
                Text(
                    text = "+",
                    style = MaterialTheme.typography.titleLarge,
                )
            }
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = 20.dp),
            contentPadding = PaddingValues(bottom = 96.dp, top = 8.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            item {
                AnimatedVisibility(
                    visible = showEnterAnimation,
                    enter = fadeIn() + slideInVertically { it / 8 },
                    exit = fadeOut() + slideOutVertically(),
                ) {
                    WeeklySummaryHeader(
                        weeklyPercent = uiState.weeklyCompletionPercent,
                        bestStreakDays = uiState.bestStreakDays,
                    )
                }
            }

            item {
                AnimatedVisibility(
                    visible = showEnterAnimation,
                    enter = fadeIn() + slideInVertically { it / 6 },
                    exit = fadeOut() + slideOutVertically(),
                ) {
                    ElevatedCard(
                        modifier = Modifier.fillMaxWidth(),
                        shape = MaterialTheme.shapes.extraLarge,
                        elevation = CardDefaults.elevatedCardElevation(defaultElevation = 10.dp),
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 22.dp, vertical = 22.dp),
                        ) {
                            Text(
                                text = "This week's habits",
                                style = MaterialTheme.typography.headlineSmall,
                            )
                            Text(
                                text = "Weekly completion ${uiState.weeklyCompletionPercent}%",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                modifier = Modifier.padding(top = 6.dp, bottom = 16.dp),
                            )

                            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)

                            LazyColumn(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(top = 18.dp),
                                userScrollEnabled = false,
                                verticalArrangement = Arrangement.spacedBy(14.dp),
                            ) {
                                items(
                                    items = uiState.habits,
                                    key = { it.id },
                                ) { habit ->
                                    HabitProgressCard(
                                        habit = habit,
                                        onClick = { onHabitClick(habit) },
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun WeeklySummaryHeader(
    weeklyPercent: Int,
    bestStreakDays: Int,
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(
            text = "Your week at a glance",
            style = MaterialTheme.typography.titleMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(
            text = "$weeklyPercent% completed overall",
            style = MaterialTheme.typography.headlineSmall,
        )
        Text(
            text = "Best streak: $bestStreakDays days",
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true, name = "Habits · Light")
@Composable
private fun HabitDashboardPreviewLight() {
    HabitsTheme(darkTheme = false, dynamicColor = false) {
        Box(modifier = Modifier.fillMaxSize()) {
            HabitDashboardContent(
                uiState = HabitDashboardUiState(habits = HabitDashboardViewModel.sampleHabits),
                onHabitClick = {},
                onDemoProgressBump = {},
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Preview(showBackground = true, name = "Habits · Dark")
@Composable
private fun HabitDashboardPreviewDark() {
    HabitsTheme(darkTheme = true, dynamicColor = false) {
        Box(modifier = Modifier.fillMaxSize()) {
            HabitDashboardContent(
                uiState = HabitDashboardUiState(habits = HabitDashboardViewModel.sampleHabits),
                onHabitClick = {},
                onDemoProgressBump = {},
            )
        }
    }
}
