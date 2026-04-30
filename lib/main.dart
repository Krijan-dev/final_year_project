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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Life Pattern Tracker",
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
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
//testing comment