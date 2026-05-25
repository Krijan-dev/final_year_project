import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/cloud_sync_service.dart";
import "package:life_pattern_tracker/screens/account_screen.dart";
import "package:life_pattern_tracker/screens/apps_screen.dart";
import "package:life_pattern_tracker/screens/dashboard_screen.dart";
import "package:life_pattern_tracker/widgets/floating_chat_overlay.dart";
import "package:life_pattern_tracker/screens/habit_screen.dart";
import "package:life_pattern_tracker/screens/insights_screen.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  String? _lastCloudSyncEmail;
  bool _cloudSyncRunning = false;

  Future<void> _restoreFromCloudAndRefresh() async {
    if (_cloudSyncRunning) return;
    _cloudSyncRunning = true;
    try {
      await CloudSyncService.syncOnSignIn();
      await ref.read(usageProvider.notifier).reloadFromStorage();
      await ref.read(habitTrackerProvider.notifier).refresh();
      if (ref.read(usageProvider).hasPermission) {
        await ref.read(usageProvider.notifier).refreshToday();
      }
    } finally {
      _cloudSyncRunning = false;
    }
  }

  void _scheduleCloudSyncIfNeeded(AuthState auth) {
    if (!auth.ready || !auth.isSignedIn || auth.email == null) {
      _lastCloudSyncEmail = null;
      return;
    }
    if (_lastCloudSyncEmail == auth.email) return;
    _lastCloudSyncEmail = auth.email;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restoreFromCloudAndRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    _scheduleCloudSyncIfNeeded(auth);
    final state = ref.watch(usageProvider);
    const pages = [
      DashboardScreen(),
      HabitScreen(),
      InsightsScreen(),
      AppsScreen(),
      AccountScreen(),
    ];
    final safeIndex = _index.clamp(0, pages.length - 1);
    if (safeIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _index = safeIndex);
        }
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF111420) : Colors.white;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          AppGradientBackground(
            dark: isDark,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  if (state.syncing) const LinearProgressIndicator(minHeight: 2),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: KeyedSubtree(key: ValueKey(safeIndex), child: pages[safeIndex]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const FloatingChatOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: navBg,
        surfaceTintColor: navBg,
        elevation: 2,
        shadowColor: Colors.black26,
        selectedIndex: safeIndex,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.check_circle_outline), label: "Habit"),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: "Insights"),
          NavigationDestination(icon: Icon(Icons.apps_outlined), label: "Apps"),
          NavigationDestination(icon: Icon(Icons.person_outline), label: "Account"),
        ],
      ),
    );
  }
}
