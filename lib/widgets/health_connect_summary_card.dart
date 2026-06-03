import "dart:io";

import "package:flutter/material.dart";
import "package:life_pattern_tracker/services/health_connect_service.dart";
import "package:life_pattern_tracker/widgets/health_connect_prompt.dart";

/// Shows today’s steps and recent sleep from Health Connect on dashboards / habits.
class HealthConnectSummaryCard extends StatefulWidget {
  const HealthConnectSummaryCard({super.key});

  @override
  State<HealthConnectSummaryCard> createState() => _HealthConnectSummaryCardState();
}

class _HealthConnectSummaryCardState extends State<HealthConnectSummaryCard> {
  bool _loading = true;
  HealthConnectData? _data;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    if (!Platform.isAndroid) return;

    setState(() => _loading = true);
    final result = await HealthConnectService.load(includeWeekTrend: false);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _data = result;
    });
  }

  Future<void> _grantHealthAccess() async {
    setState(() => _loading = true);
    final result = await HealthConnectService.requestPermissions();
    if (!mounted) return;
    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message!)),
      );
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(minHeight: 3),
        ),
      );
    }

    final data = _data;
    if (data == null) return const SizedBox.shrink();

    if (data.needsInstall || data.needsPermission || !data.hasData) {
      return HealthConnectPromptCard(
        data: data,
        onGrantAccess: _grantHealthAccess,
        onInstall: () async {
          await HealthConnectService.installOrUpdateHealthConnect();
          if (mounted) await _load();
        },
        onRetry: _load,
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_walk, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "${data.stepsToday ?? 0} steps today",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Refresh",
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.sleepHoursLastNight != null
                  ? "Sleep last night: ${data.sleepHoursLastNight!.toStringAsFixed(1)} h"
                  : "Sleep: no session recorded yet",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
