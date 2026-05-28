import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/cloud_sync_service.dart";
import "package:life_pattern_tracker/screens/dashboard_screen.dart";
import "package:life_pattern_tracker/screens/more_hub_screen.dart";
import "package:life_pattern_tracker/widgets/floating_chat_overlay.dart";
import "package:life_pattern_tracker/screens/habit_screen.dart";
import "package:life_pattern_tracker/screens/insights_screen.dart";
import "package:life_pattern_tracker/screens/screen_time_screen.dart";
import "package:life_pattern_tracker/screens/account_screen.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";
import "package:life_pattern_tracker/widgets/subpage_scaffold.dart";

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  String? _lastCloudSyncEmail;
  bool _cloudSyncRunning = false;

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
    if (state == AppLifecycleState.resumed) {
      // Usage Access is granted in Android settings, so re-check when user returns.
      ref.read(usageProvider.notifier).checkPermission();
    }
  }

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

  void _openAccount() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SubpageScaffold(
          title: "Account",
          child: AccountScreen(embeddedInSubpage: true),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    _scheduleCloudSyncIfNeeded(auth);
    final state = ref.watch(usageProvider);
    const pages = [
      DashboardScreen(),
      ScreenTimeScreen(),
      HabitScreen(),
      InsightsScreen(),
      MoreHubScreen(),
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
          Positioned(
            top: 10,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _openAccount,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                      ),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4D1D4ED8),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lock_outline, color: Colors.white, size: 19),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 4),
        child: Theme(
          data: Theme.of(context).copyWith(
            navigationBarTheme: NavigationBarThemeData(
              height: 64,
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                final selected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                return IconThemeData(
                  size: states.contains(WidgetState.selected) ? 26 : 24,
                );
              }),
            ),
          ),
          child: NavigationBar(
            backgroundColor: navBg,
            surfaceTintColor: navBg,
            elevation: 2,
            shadowColor: Colors.black26,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: safeIndex,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: "Home",
              ),
              NavigationDestination(
                icon: Icon(Icons.smartphone_outlined),
                selectedIcon: Icon(Icons.smartphone),
                label: "Time",
              ),
              NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
                label: "Habits",
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights),
                label: "Insights",
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz),
                selectedIcon: Icon(Icons.more_horiz),
                label: "More",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
