import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";

class PermissionOnboardingScreen extends ConsumerStatefulWidget {
  const PermissionOnboardingScreen({super.key});

  @override
  ConsumerState<PermissionOnboardingScreen> createState() =>
      _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends ConsumerState<PermissionOnboardingScreen>
    with WidgetsBindingObserver {
  AppLifecycleState? _lastLifecycle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_lastLifecycle == AppLifecycleState.paused &&
        state == AppLifecycleState.resumed) {
      ref.read(usageProvider.notifier).checkPermission();
    }
    _lastLifecycle = state;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_clock_outlined,
                size: 84,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                "Enable Usage Access",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              const Text(
                "To track screen time and app usage patterns, Android requires Usage Access permission.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(usageProvider.notifier).openUsageSettings();
                },
                icon: const Icon(Icons.settings),
                label: const Text("Open Usage Access Settings"),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(usageProvider.notifier).checkPermission();
                },
                child: const Text("I granted permission"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
