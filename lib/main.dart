import "dart:io";

import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/theme_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/screens/home_shell.dart";
import "package:life_pattern_tracker/screens/permission_onboarding_screen.dart";
import "package:life_pattern_tracker/screens/welcome_screen.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: LifePatternApp()));
}

class LifePatternApp extends ConsumerWidget {
  const LifePatternApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Rebuild MaterialApp only when permission gate changes — not on every sync tick.
    final permissionGate = ref.watch(
      usageProvider.select((s) => (s.initialCheckComplete, s.hasPermission)),
    );
    final auth = ref.watch(authProvider);
    final lightScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Life Pattern Tracker",
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: Colors.transparent,
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
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black26,
          indicatorColor: AppColors.green.withValues(alpha: 0.18),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightScheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: lightScheme.outlineVariant),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        scaffoldBackgroundColor: Colors.transparent,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1A1D28),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF111420).withValues(alpha: 0.92),
          elevation: 1,
          indicatorColor: AppColors.green.withValues(alpha: 0.28),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            );
          }),
        ),
      ),
      home: Platform.isAndroid
          ? !permissionGate.$1
              ? const AppGradientBackground(
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(child: CircularProgressIndicator()),
                  ),
                )
              : !permissionGate.$2
                  ? const AppGradientBackground(child: PermissionOnboardingScreen())
                  : !auth.ready
                      ? const AppGradientBackground(
                          child: Scaffold(
                            backgroundColor: Colors.transparent,
                            body: Center(child: CircularProgressIndicator()),
                          ),
                        )
                      : !auth.isSignedIn
                          ? const AppGradientBackground(child: WelcomeScreen())
                          : const HomeShell()
          : const AppGradientBackground(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: Text("Usage tracking is available only on Android."),
                ),
              ),
            ),
    );
  }
}
