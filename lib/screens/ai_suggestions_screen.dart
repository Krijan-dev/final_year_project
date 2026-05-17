import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/gemini_service.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

class AiSuggestionsScreen extends ConsumerStatefulWidget {
  const AiSuggestionsScreen({super.key});

  @override
  ConsumerState<AiSuggestionsScreen> createState() => _AiSuggestionsScreenState();
}

class _AiSuggestionsScreenState extends ConsumerState<AiSuggestionsScreen> {
  late Future<List<_Suggestion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_Suggestion>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorView(onRetry: _refresh);
        }

        final suggestions = snapshot.data ?? const <_Suggestion>[];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      GeminiService.isConfigured
                          ? "Personalized by Gemini"
                          : "Fallback suggestions (Gemini key missing)",
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh"),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final item = suggestions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: Icon(item.icon),
                      title: Text(item.title),
                      subtitle: Text(item.description),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadSuggestions();
    });
  }

  Future<List<_Suggestion>> _loadSuggestions() async {
    final state = ref.read(usageProvider);
    final notifier = ref.read(usageProvider.notifier);
    final today = state.today?.totalScreenTime ?? 0;
    final avg = notifier.averageDailyMinutes();
    final focus = notifier.focusScore();
    final productivity = notifier.productivityScore();
    final fallback = _buildSuggestions(
      todayMinutes: today,
      averageMinutes: avg,
      focusScore: focus,
      productivityScore: productivity,
    ).toList();

    if (!GeminiService.isConfigured) return fallback;

    try {
      final aiLines = await GeminiService.generateSuggestions(
        todayMinutes: today,
        averageMinutes: avg,
        focusScore: focus,
        productivityScore: productivity,
      );
      if (aiLines.isEmpty) return fallback;
      return aiLines
          .asMap()
          .entries
          .map(
            (entry) => _Suggestion(
              title: "AI Suggestion ${entry.key + 1}",
              description: entry.value,
              icon: _iconForIndex(entry.key),
            ),
          )
          .toList();
    } catch (_) {
      return fallback;
    }
  }

  Iterable<_Suggestion> _buildSuggestions({
    required int todayMinutes,
    required int averageMinutes,
    required int focusScore,
    required int productivityScore,
  }) {
    final items = <_Suggestion>[];

    if (todayMinutes > averageMinutes + 60) {
      items.add(
        _Suggestion(
          title: "Reduce extended sessions",
          description:
              "Today's usage (${formatMinutes(todayMinutes)}) is above average. Add a timer for 45-minute sessions.",
          icon: Icons.timer_outlined,
        ),
      );
    }

    if (focusScore < 60) {
      items.add(
        const _Suggestion(
          title: "Focus recovery plan",
          description: "Mute social notifications during study/work blocks to reduce context switching.",
          icon: Icons.notifications_off_outlined,
        ),
      );
    }

    if (productivityScore < 70) {
      items.add(
        const _Suggestion(
          title: "Prioritize productive apps",
          description: "Open your top productive app first each hour to anchor better usage habits.",
          icon: Icons.rocket_launch_outlined,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        const _Suggestion(
          title: "Maintain current routine",
          description: "Your metrics look balanced. Keep your current focus rhythm and review weekly trends.",
          icon: Icons.check_circle_outline,
        ),
      );
    }

    items.add(
      _Suggestion(
        title: "Daily target",
        description: "Aim for about ${formatMinutes((averageMinutes * 0.9).round())} tomorrow.",
        icon: Icons.flag_outlined,
      ),
    );

    return items;
  }

  IconData _iconForIndex(int index) {
    const icons = [
      Icons.bolt_outlined,
      Icons.timer_outlined,
      Icons.track_changes_outlined,
      Icons.self_improvement_outlined,
    ];
    return icons[index % icons.length];
  }
}

class _Suggestion {
  const _Suggestion({required this.title, required this.description, required this.icon});
  final String title;
  final String description;
  final IconData icon;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Could not load AI suggestions."),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: const Text("Try again")),
        ],
      ),
    );
  }
}
