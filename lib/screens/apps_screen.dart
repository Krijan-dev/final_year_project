import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/widgets/app_usage_tile.dart";

class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(usageProvider);
    final today = state.today;

    if (today == null || today.appUsages.isEmpty) {
      return const Center(child: Text("No app usage data available yet."));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: today.appUsages.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final app = today.appUsages[index];
        return AppUsageTile(
          app: app,
          totalMinutes: today.totalScreenTime,
        );
      },
    );
  }
}
