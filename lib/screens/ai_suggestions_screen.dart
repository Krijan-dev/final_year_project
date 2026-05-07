import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

class AiSuggestionsScreen extends ConsumerWidget {
  const AiSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);
    final notifier = ref.read(usageProvider.notifier);
    final today = state.today?.totalScreenTime ?? 0;
    final avg = notifier.averageDailyMinutes();
    final focus = notifier.focusScore();
    final productivity = notifier.productivityScore();
    final suggestions = _buildSuggestions(
      todayMinutes: today,
      averageMinutes: avg,
      focusScore: focus,
      productivityScore: productivity,
    );

    return ListView.builder(
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
    );
  }

  List<_Suggestion> _buildSuggestions({
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
}

class _Suggestion {
  const _Suggestion({required this.title, required this.description, required this.icon});
  final String title;
  final String description;
  final IconData icon;
}
