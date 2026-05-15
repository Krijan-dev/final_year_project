import "dart:io";

import "package:flutter/material.dart";
import "package:health/health.dart";
import "package:permission_handler/permission_handler.dart";

/// Shows today’s steps and recent sleep from [Health Connect](https://health.google/health-connect-android/)
/// when Samsung Health, Google Fit, Wear OS, Galaxy Watch, etc. sync into Health Connect.
class HealthConnectSummaryCard extends StatefulWidget {
  const HealthConnectSummaryCard({super.key});

  @override
  State<HealthConnectSummaryCard> createState() => _HealthConnectSummaryCardState();
}

class _HealthConnectSummaryCardState extends State<HealthConnectSummaryCard> {
  static const List<HealthDataType> _authTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
  ];

  bool _loading = true;
  String? _error;
  int? _stepsToday;
  double? _sleepHoursLastNight;

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

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final motion = await Permission.activityRecognition.request();
      if (!motion.isGranted) {
        setState(() {
          _loading = false;
          _error = "Allow physical activity access so step counts can be read.";
        });
        return;
      }

      final health = Health();
      await health.configure();

      final sdk = await health.getHealthConnectSdkStatus();
      if (sdk != HealthConnectSdkStatus.sdkAvailable) {
        setState(() {
          _loading = false;
          _error = "Install or update Health Connect from the Play Store, then open this tab again.";
        });
        return;
      }

      final reads = List<HealthDataAccess>.filled(_authTypes.length, HealthDataAccess.READ);
      final has = await health.hasPermissions(_authTypes, permissions: reads);
      if (has != true) {
        await health.requestAuthorization(_authTypes, permissions: reads);
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final steps = await health.getTotalStepsInInterval(startOfDay, now);

      final sleepEnd = now;
      final sleepStart = startOfDay.subtract(const Duration(hours: 18));
      var sleepPoints = await health.getHealthDataFromTypes(
        types: const [HealthDataType.SLEEP_SESSION],
        startTime: sleepStart,
        endTime: sleepEnd,
      );

      double sleepHours = 0;
      if (sleepPoints.isNotEmpty) {
        for (final p in sleepPoints) {
          sleepHours += p.dateTo.difference(p.dateFrom).inMinutes / 60.0;
        }
      } else {
        sleepPoints = await health.getHealthDataFromTypes(
          types: const [HealthDataType.SLEEP_ASLEEP],
          startTime: sleepStart,
          endTime: sleepEnd,
        );
        for (final p in sleepPoints) {
          sleepHours += p.dateTo.difference(p.dateFrom).inMinutes / 60.0;
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _stepsToday = steps ?? 0;
        _sleepHoursLastNight = sleepHours > 0 ? sleepHours : null;
      });
    } catch (e, st) {
      debugPrint("HealthConnectSummaryCard: $e\n$st");
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = "Could not read Health Connect data. Grant permissions in system settings if needed.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final border = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_outlined, color: theme.colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "From your phone (Health Connect)",
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: "Refresh",
                  onPressed: _loading ? null : _load,
                  icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "Steps and sleep sync from apps and watches that write to Health Connect (e.g. Samsung Health when supported).",
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (_loading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 3),
            ],
            const SizedBox(height: 14),
            if (_error != null)
              Text(_error!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error))
            else if (!_loading)
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: "Steps today",
                      value: _stepsToday == null ? "—" : "${_stepsToday!}",
                      icon: Icons.directions_walk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricTile(
                      label: "Recent sleep",
                      value: _sleepHoursLastNight == null
                          ? "—"
                          : "${_sleepHoursLastNight!.toStringAsFixed(1)} h",
                      icon: Icons.bedtime_outlined,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
