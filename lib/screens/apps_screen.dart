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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            state.syncing
                ? "Loading today’s screen time…"
                : "No app usage data available yet.\n"
                    "Enable Usage access and pull to refresh.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final sumAppMinutes = today.appUsages.fold<int>(0, (sum, a) => sum + a.usageTime);
    final percentBase = sumAppMinutes > 0 ? sumAppMinutes : 1;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: today.appUsages.length,
      itemBuilder: (context, index) {
        final app = today.appUsages[index];
        return AppUsageTile(
          app: app,
          totalMinutes: percentBase,
        );
      },
    );
  }
}
