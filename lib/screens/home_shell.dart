import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/screens/ai_suggestions_screen.dart";
import "package:life_pattern_tracker/screens/apps_screen.dart";
import "package:life_pattern_tracker/screens/charts_screen.dart";
import "package:life_pattern_tracker/screens/chatbot_screen.dart";
import "package:life_pattern_tracker/screens/dashboard_screen.dart";
import "package:life_pattern_tracker/screens/insights_screen.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";
import "package:life_pattern_tracker/services/gemini_service.dart";

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
    const titles = [
      "Dashboard",
      "Charts",
      "Chatbot",
      "AI Suggestions",
      "Insights",
      "Apps",
    ];
    final geminiChatKey = ValueKey<String>(
      "gemini_${GeminiService.isConfigured}_${GeminiService.resolvedApiKey.length}",
    );
    final pages = [
      const DashboardScreen(),
      const ChartsScreen(),
      ChatbotScreen(key: geminiChatKey),
      AiSuggestionsScreen(key: geminiChatKey),
      const InsightsScreen(),
      const AppsScreen(),
    ];
    final safeIndex = _index.clamp(0, pages.length - 1);
    if (safeIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _index = safeIndex);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[safeIndex],
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              onPressed: () {
                notifier.loadDemoUsage();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Demo: 7 days of sample usage loaded. Tap refresh to restore real stats.",
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.science_outlined),
              tooltip: "Load demo usage",
            ),
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
              } else if (value == "debug_gemini" && kDebugMode) {
                await _promptDebugGeminiKey();
              }
            },
            itemBuilder: (context) => [
              if (kDebugMode) ...[
                const PopupMenuItem(value: "debug_gemini", child: Text("Paste Gemini key (debug)")),
                const PopupMenuDivider(),
              ],
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              child: KeyedSubtree(key: ValueKey(safeIndex), child: pages[safeIndex]),
            ),
          ),
          if (state.syncing) const LinearProgressIndicator(minHeight: 2),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: "Dashboard"),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: "Charts"),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: "Chatbot"),
          NavigationDestination(icon: Icon(Icons.psychology_outlined), label: "AI"),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: "Insights"),
          NavigationDestination(icon: Icon(Icons.apps_outlined), label: "Apps"),
        ],
      ),
    );
  }

  Future<void> _promptDebugGeminiKey() async {
    if (!kDebugMode) return;
    final controller = TextEditingController();
    try {
      final result = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Debug: Gemini API key"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(hintText: "Paste key (stored on device, debug only)"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ""),
              child: const Text("Clear"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text("Save"),
            ),
          ],
        ),
      );
      if (!mounted || result == null) return;
      await GeminiKeyStore.writeDebugOverride(result.isEmpty ? null : result);
      if (!mounted) return;
      setState(() {});
    } finally {
      controller.dispose();
    }
  }
}
