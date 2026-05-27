package com.example.life_pattern_tracker.habits.ui.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp

private val ColorWhite = Color(0xFFFFFFFF)

private val LightColors = lightColorScheme(
    primary = ProgressNavy,
    onPrimary = ColorWhite,
    primaryContainer = Color(0xFFD7E6FF),
    onPrimaryContainer = ProgressNavy,
    surface = Color(0xFFF4F6FA),
    onSurface = Color(0xFF101828),
    surfaceContainerHigh = HabitCardLight,
    outlineVariant = Color(0xFFE1E6EE),
)

private val DarkColors = darkColorScheme(
    primary = Color(0xFF9BB7D9),
    onPrimary = Color(0xFF0B1626),
    primaryContainer = Color(0xFF1E3552),
    onPrimaryContainer = Color(0xFFD7E6FF),
    surface = Color(0xFF0B0F14),
    onSurface = Color(0xFFE9EEF5),
    surfaceContainerHigh = HabitCardDark,
    outlineVariant = Color(0xFF343F50),
)

@Composable
fun HabitsTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else -> LightColors
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = HabitTypography,
        shapes = Shapes(
            extraLarge = RoundedCornerShape(28.dp),
            large = RoundedCornerShape(20.dp),
            medium = RoundedCornerShape(16.dp),
        ),
        content = content,
    )
}
