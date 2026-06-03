import "dart:io";

import "package:flutter/material.dart";
import "package:life_pattern_tracker/services/health_connect_service.dart";
import "package:life_pattern_tracker/widgets/account_avatar_button.dart";
import "package:life_pattern_tracker/widgets/health_connect_prompt.dart";

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, this.embeddedInSubpage = false});

  /// When opened from More → Health, the app bar already shows the title.
  final bool embeddedInSubpage;

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with WidgetsBindingObserver {
  bool _loading = true;
  HealthConnectData? _data;

  int? _stepsToday;
  double? _sleepHoursLastNight;
  List<HealthDaySteps>? _stepsLast7Days;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isAndroid) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loading) {
      _load();
    }
  }

  Future<void> _load({bool requestPermission = false}) async {
    setState(() => _loading = true);

    final result = await HealthConnectService.load(
      requestPermissionIfNeeded: requestPermission,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _data = result;
      _stepsToday = result.permissionsGranted ? result.stepsToday : null;
      _sleepHoursLastNight = result.sleepHoursLastNight;
      _stepsLast7Days =
          result.stepsLast7Days.isNotEmpty ? result.stepsLast7Days : null;
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
    return RefreshIndicator(
      onRefresh: () async {
        if (_loading) return;
        await _load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, widget.embeddedInSubpage ? 4 : 8, 16, 24),
        children: [
          if (!widget.embeddedInSubpage) const SizedBox(height: 8),
          _Header(
            title: "Health Connect",
            subtitle: "Steps + sleep from your phone's Health Connect.",
            compact: widget.embeddedInSubpage,
            action: IconButton(
              tooltip: "Refresh",
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 10),
          if (_data != null)
            _HealthPermissionStatusBar(data: _data!),
          const SizedBox(height: 16),
          if (_loading) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            ),
          ] else if (_data != null &&
              (_data!.needsInstall || _data!.needsPermission)) ...[
            HealthConnectPromptCard(
              data: _data!,
              onGrantAccess: _grantHealthAccess,
              onInstall: () async {
                await HealthConnectService.installOrUpdateHealthConnect();
                if (mounted) await _load();
              },
              onRetry: _load,
            ),
          ] else if (_data != null && _data!.permissionsGranted && !_data!.hasData) ...[
            _OverviewCard(
              stepsToday: _stepsToday ?? 0,
              sleepHoursLastNight: _sleepHoursLastNight,
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _data!.errorMessage ?? HealthConnectService.genericSyncHint,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ] else ...[
            _OverviewCard(
              stepsToday: _stepsToday ?? 0,
              sleepHoursLastNight: _sleepHoursLastNight,
            ),
            const SizedBox(height: 14),
            _WellnessScoreCard(
              stepsToday: _stepsToday ?? 0,
              sleepHoursLastNight: _sleepHoursLastNight,
            ),
            const SizedBox(height: 14),
            if (_stepsLast7Days != null) _StepsTrendCard(steps: _stepsLast7Days!),
            const SizedBox(height: 14),
            _TipsCard(
              stepsToday: _stepsToday ?? 0,
              sleepHoursLastNight: _sleepHoursLastNight,
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}

class _HealthPermissionStatusBar extends StatelessWidget {
  const _HealthPermissionStatusBar({required this.data});

  final HealthConnectData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = data.permissionsGranted;
    final needsHcApp = data.needsInstall;
    final ok = granted;
    final bg = ok
        ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
        : theme.colorScheme.errorContainer.withValues(alpha: 0.35);
    final fg = ok ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onErrorContainer;

    String label;
    if (needsHcApp && !granted) {
      label = "Health Connect app needed — install or open below";
    } else if (!granted) {
      label = "Health Connect: allow Steps & Sleep for this app below";
    } else if (!data.hasData) {
      label = "Health Connect: allowed — waiting for steps/sleep data";
    } else {
      label = "Health Connect: connected — reading steps and sleep";
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(ok ? Icons.favorite_outline : Icons.lock_outline, size: 20, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.action,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final Widget action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.monitor_heart_outlined, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              action,
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const AccountAvatarButton(),
            const SizedBox(width: 6),
            action,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.stepsToday,
    required this.sleepHoursLastNight,
  });

  final int stepsToday;
  final double? sleepHoursLastNight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface.withValues(alpha: 0.84),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today overview",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.directions_walk,
                    label: "Steps today",
                    value: "$stepsToday",
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.bedtime_outlined,
                    label: "Sleep (last night)",
                    value: sleepHoursLastNight == null
                        ? "—"
                        : "${sleepHoursLastNight!.toStringAsFixed(1)} h",
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

class _WellnessScoreCard extends StatelessWidget {
  const _WellnessScoreCard({
    required this.stepsToday,
    required this.sleepHoursLastNight,
  });

  final int stepsToday;
  final double? sleepHoursLastNight;

  @override
  Widget build(BuildContext context) {
    const stepsGoal = 8000.0;
    const sleepGoal = 8.0;
    final stepsScore = (stepsToday / stepsGoal).clamp(0.0, 1.0);
    final sleepScore = ((sleepHoursLastNight ?? 0) / sleepGoal).clamp(0.0, 1.0);
    final wellness = ((stepsScore * 0.6) + (sleepScore * 0.4)).clamp(0.0, 1.0);

    final theme = Theme.of(context);
    final pct = (wellness * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.secondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Wellness score",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
                    child: Text(
                      "$pct",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Balanced steps + sleep",
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: wellness,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Steps goal: ${(stepsScore * 100).round()}% · Sleep goal: ${(sleepScore * 100).round()}%",
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepsTrendCard extends StatelessWidget {
  const _StepsTrendCard({required this.steps});

  final List<HealthDaySteps> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxSteps = steps.map((e) => e.steps).fold<int>(0, (a, b) => a > b ? a : b).clamp(1, 1000000);
    const maxBarHeight = 120.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "7-day steps trend",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: maxBarHeight + 32,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final d in steps) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: (d.steps / maxSteps) * maxBarHeight,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              d.label,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({
    required this.stepsToday,
    required this.sleepHoursLastNight,
  });

  final int stepsToday;
  final double? sleepHoursLastNight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const stepsGoal = 8000;
    const sleepGoal = 8.0;

    final tips = <String>[];
    if (stepsToday < stepsGoal * 0.6) {
      tips.add("Take a 10-minute walk today — small movement adds up.");
    } else if (stepsToday < stepsGoal) {
      tips.add("You're close. Add one more short activity session.");
    } else {
      tips.add("Great movement today. Keep your steps consistent.");
    }

    final sleep = sleepHoursLastNight ?? 0.0;
    if (sleep < sleepGoal * 0.7) {
      tips.add("Try shifting bedtime earlier by 20-30 minutes tonight.");
    } else if (sleep < sleepGoal) {
      tips.add("Aim for a full 8 hours to maximize recovery.");
    } else {
      tips.add("Nice sleep. Your recovery window looks solid.");
    }

    tips.add("Pull to refresh on Health after changing Health Connect permissions.");

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Standout health tips",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
