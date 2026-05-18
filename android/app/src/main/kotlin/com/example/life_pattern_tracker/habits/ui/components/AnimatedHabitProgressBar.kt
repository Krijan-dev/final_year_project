package com.example.life_pattern_tracker.habits.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import com.example.life_pattern_tracker.habits.ui.theme.ProgressNavy
import com.example.life_pattern_tracker.habits.ui.theme.ProgressNavyEnd

@Composable
fun AnimatedHabitProgressBar(
    progress: Float,
    modifier: Modifier = Modifier,
    useGradient: Boolean,
) {
    val target = progress.coerceIn(0f, 1f)
    val animated by animateFloatAsState(
        targetValue = target,
        animationSpec = tween(durationMillis = 650),
        label = "habitLinearProgress",
    )

    val track = MaterialTheme.colorScheme.outlineVariant
    val shape = RoundedCornerShape(percent = 50)

    BoxWithConstraints(
        modifier = modifier
            .height(10.dp)
            .fillMaxWidth()
            .clip(shape)
            .background(track),
    ) {
        val fillWidth = maxWidth * animated
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .width(fillWidth)
                .clip(shape)
                .background(
                    brush = if (useGradient) {
                        Brush.horizontalGradient(
                            colors = listOf(ProgressNavy, ProgressNavyEnd),
                        )
                    } else {
                        Brush.horizontalGradient(
                            colors = listOf(ProgressNavy, ProgressNavy),
                        )
                    },
                ),
        )
    }
}
