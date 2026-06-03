import "package:flutter/material.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        indicatorColor: AppColors.green.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.6)),
    );
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.greenAccent,
      onPrimary: Color(0xFF052E16),
      primaryContainer: Color(0xFF166534),
      onPrimaryContainer: Color(0xFFBBF7D0),
      secondary: Color(0xFF86EFAC),
      onSecondary: Color(0xFF052E16),
      secondaryContainer: Color(0xFF14532D),
      onSecondaryContainer: Color(0xFFD1FAE5),
      tertiary: Color(0xFF93C5FD),
      onTertiary: Color(0xFF0C1A3A),
      error: Color(0xFFF87171),
      onError: Color(0xFF450A0A),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkOnSurface,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline: Color(0xFF5C6B7E),
      outlineVariant: Color(0xFF3D4A5C),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE8EDF3),
      onInverseSurface: Color(0xFF1F2630),
      inversePrimary: AppColors.greenDark,
      surfaceTint: AppColors.greenAccent,
      surfaceContainerHighest: AppColors.darkSurfaceHigh,
      surfaceContainerHigh: AppColors.darkSurfaceElevated,
      surfaceContainer: Color(0xFF262F3B),
      surfaceContainerLow: Color(0xFF232B36),
      surfaceContainerLowest: Color(0xFF1A2129),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        ),
        color: AppColors.darkCard,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.darkOnSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkNavBar,
        surfaceTintColor: AppColors.darkNavBar,
        elevation: 0,
        indicatorColor: AppColors.greenAccent.withValues(alpha: 0.22),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.greenAccent : AppColors.darkOnSurfaceVariant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.greenAccent : AppColors.darkOnSurfaceVariant,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: const TextStyle(color: AppColors.darkOnSurfaceVariant),
        hintStyle: TextStyle(color: AppColors.darkOnSurfaceVariant.withValues(alpha: 0.85)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.greenAccent, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceHigh,
        contentTextStyle: const TextStyle(color: AppColors.darkOnSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.greenAccent.withValues(alpha: 0.2);
            }
            return AppColors.darkSurfaceHigh;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.greenAccent;
            }
            return AppColors.darkOnSurfaceVariant;
          }),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.greenAccent,
      ),
    );
  }
}
