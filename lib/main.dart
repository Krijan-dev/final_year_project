import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/theme_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/screens/home_shell.dart";
import "package:life_pattern_tracker/screens/permission_onboarding_screen.dart";
import "package:life_pattern_tracker/screens/welcome_screen.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<dynamic>("app_settings");
  if (kDebugMode) {
    const compileKey = String.fromEnvironment("GEMINI_API_KEY");
    debugPrint(
      "GEMINI_API_KEY compile-time length: ${compileKey.length} "
      "(0 = start app with .\\run_dev.ps1, launch config, or VS Code Flutter args so "
      "--dart-define-from-file=.env is applied)",
    );
  }
  runApp(const ProviderScope(child: LifePatternApp()));
}

class LifePatternApp extends ConsumerWidget {
  const LifePatternApp({super.key});
//testing comment
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    // Rebuild MaterialApp only when permission gate changes — not on every sync tick.
    final permissionGate = ref.watch(
      usageProvider.select((s) => (s.initialCheckComplete, s.hasPermission)),
    );
    final auth = ref.watch(authProvider);
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF4F46E5),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6366F1),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Life Pattern Tracker",
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: const Color(0xFFF6F7FB),
          foregroundColor: lightScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          elevation: 1,
          indicatorColor: lightScheme.primary.withValues(alpha: 0.16),
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
        scaffoldBackgroundColor: const Color(0xFF0F1117),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: const Color(0xFF1A1D28),
          margin: EdgeInsets.zero,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: const Color(0xFF0F1117),
          foregroundColor: darkScheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF111420),
          elevation: 1,
          indicatorColor: darkScheme.primary.withValues(alpha: 0.22),
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
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : !permissionGate.$2
                  ? const PermissionOnboardingScreen()
                  : !auth.ready
                      ? const Scaffold(
                          body: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : !auth.isSignedIn
                          ? const WelcomeScreen()
                          : const HomeShell()
          : const Scaffold(
              body: Center(
                child: Text("Usage tracking is available only on Android."),
              ),
            ),
    );
  }
}
