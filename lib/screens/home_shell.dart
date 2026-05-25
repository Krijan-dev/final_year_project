import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
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

  @override
  Widget build(BuildContext context) {
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
