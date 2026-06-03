import "dart:io";

import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/theme_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/screens/home_shell.dart";
import "package:life_pattern_tracker/screens/welcome_screen.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";
import "package:life_pattern_tracker/theme/app_theme.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _safeStartupInit();
  runApp(const ProviderScope(child: LifePatternApp()));
}

Future<void> _safeStartupInit() async {
  await _safeFirebaseInit();

  try {
    await dotenv.load(fileName: "flutter.env").timeout(const Duration(seconds: 3));
  } catch (_) {
    try {
      await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 3));
    } catch (_) {
      // Use run_dev.ps1 or --dart-define-from-file=flutter.env
    }
  }

  try {
    await Hive.initFlutter().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Continue with defaults if local storage init is delayed/failed.
  }

  try {
    await Hive.openBox<dynamic>(kAppSettingsBoxName).timeout(const Duration(seconds: 5));
    if (Hive.isBoxOpen(kAppSettingsBoxName)) {
      await Hive.box<dynamic>(kAppSettingsBoxName).delete("dev_spoof_level");
    }
  } catch (_) {
    // Don't block app launch on settings box open; app can still render.
  }
}

Future<void> _safeFirebaseInit() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp().timeout(const Duration(seconds: 6));
    }
  } catch (_) {
    // Firebase config may be missing in local/dev builds.
    // App should still launch for non-Firebase flows.
  }
}

class LifePatternApp extends ConsumerWidget {
  const LifePatternApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final usageReady = ref.watch(
      usageProvider.select((s) => s.initialCheckComplete),
    );
    final auth = ref.watch(authProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Life Pattern Tracker",
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Platform.isAndroid
          ? !usageReady
              ? const AppGradientBackground(
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    body: Center(child: CircularProgressIndicator()),
                  ),
                )
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

