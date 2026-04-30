import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/screens/apps_screen.dart";
import "package:life_pattern_tracker/screens/dashboard_screen.dart";
import "package:life_pattern_tracker/screens/insights_screen.dart";

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
    final notifier = ref.read(usageProvider.notifier);
    final sessionEmail = ref.watch(authProvider.select((a) => a.email));
    const pages = [DashboardScreen(), InsightsScreen(), AppsScreen()];
    const titles = ["Dashboard", "Insights", "Apps"];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            onPressed: () => notifier.refreshToday(),
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
          PopupMenuButton<String>(
            tooltip: "Account",
            onSelected: (value) async {
              if (value == "logout") {
                await ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              if (sessionEmail != null)
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    sessionEmail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              if (sessionEmail != null) const PopupMenuDivider(),
              const PopupMenuItem(value: "logout", child: Text("Log out")),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
          ),
          if (state.syncing) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: "Insights"),
          NavigationDestination(icon: Icon(Icons.apps_outlined), label: "Apps"),
        ],
      ),
    );
  }
}
