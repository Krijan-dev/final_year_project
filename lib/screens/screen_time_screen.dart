import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/models/installed_app_model.dart";
import "package:life_pattern_tracker/providers/screen_time_limits_provider.dart";
import "package:life_pattern_tracker/providers/dashboard_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/screen_time_limit_evaluator.dart";
import "package:life_pattern_tracker/services/dashboard_metrics_service.dart";
import "package:life_pattern_tracker/services/usage_stats_service.dart";
import "package:life_pattern_tracker/utils/formatters.dart";
import "package:life_pattern_tracker/widgets/app_icon_widget.dart";
import "package:life_pattern_tracker/widgets/app_usage_tile.dart";
import "package:life_pattern_tracker/widgets/usage_bar_chart.dart";
import "package:life_pattern_tracker/models/app_screen_time_limit.dart";
import "package:life_pattern_tracker/widgets/account_avatar_button.dart";

const Color _kGreen = Color(0xFF22C55E);
const Color _kGreenDark = Color(0xFF16A34A);

class ScreenTimeScreen extends ConsumerStatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  ConsumerState<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends ConsumerState<ScreenTimeScreen> {
  final ScreenTimeLimitEvaluator _evaluator = ScreenTimeLimitEvaluator();
  late final ProviderSubscription<DailyUsageModel?> _todayUsageSub;

  @override
  void initState() {
    super.initState();

    // Fire limit checks whenever usage refreshes.
    _todayUsageSub = ref.listenManual<DailyUsageModel?>(
      usageProvider.select((s) => s.today),
      (_, next) async {
      if (next == null) return;
      await _evaluator.evaluate(next);
    },
    );

    // Also evaluate once for the currently loaded day (when the user opens
    // this tab without doing a pull-to-refresh).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final today = ref.read(usageProvider).today;
      if (today == null) return;
      await _evaluator.evaluate(today);
    });
  }

  @override
  void dispose() {
    _todayUsageSub.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usage = ref.watch(usageProvider);
    final limitsState = ref.watch(screenTimeLimitsProvider);
    final dash = ref.watch(dashboardProvider);
    final m = dash.metrics;
    final notifier = ref.read(dashboardProvider.notifier);

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (dash.syncing) const LinearProgressIndicator(minHeight: 2),
          if (dash.usageError != null) ...[
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(dash.usageError!),
              ),
            ),
          ],
          _ScreenTimeHeader(metrics: m),
          const SizedBox(height: 12),
          _LimitsSection(
            usage: usage,
            limitsState: limitsState,
          ),
          const SizedBox(height: 16),
          if (!usage.hasPermission) _PermissionCard(ref: ref),
          if (!m.hasUsageData && usage.hasPermission)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Pull down to refresh and load today's usage.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          if (m.hasUsageData) ...[
            _TodayHeroCard(metrics: m),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ScoreChip(
                    label: "Focus",
                    score: m.focusScore,
                    icon: Icons.center_focus_strong,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ScoreChip(
                    label: "Productivity",
                    score: m.productivityScore,
                    icon: Icons.trending_up,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CategoryBreakdown(apps: usage.today?.appUsages ?? m.topApps),
            const SizedBox(height: 16),
            _ChartCard(
              title: "Hourly usage today",
              subtitle: m.peakHourLabel ?? "Peak hour unknown",
              child: SizedBox(
                height: 200,
                child: UsageBarChart(
                  values: m.hourlyMinutes,
                  maxY: m.chartMaxY,
                  hourly: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ChartCard(
              title: "Last 7 days",
              subtitle: m.averageMinutes > 0
                  ? "Avg ${formatMinutes(m.averageMinutes)} / day"
                  : "Build history by opening the app daily",
              child: SizedBox(
                height: 200,
                child: UsageBarChart(
                  values: _weekValues(usage.history),
                  maxY: _weekMax(usage.history),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "All apps today",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            if (usage.today?.appUsages.isEmpty ?? true)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("No per-app breakdown yet."),
                ),
              )
            else
              ...usage.today!.appUsages.map(
                (app) => AppUsageTile(
                  app: app,
                  totalMinutes: usage.today!.totalScreenTime,
                ),
              ),
          ],
        ],
      ),
    );
  }

  static List<int> _weekValues(List<DailyUsageModel> history) {
    final week = history.length <= 7 ? history : history.sublist(history.length - 7);
    if (week.isEmpty) return [0];
    return week.map((d) => d.totalScreenTime).toList();
  }

  static int _weekMax(List<DailyUsageModel> history) {
    final values = _weekValues(history);
    if (values.isEmpty) return 60;
    return values.reduce((a, b) => a > b ? a : b).clamp(60, 9999);
  }
}

const List<int> _kLimitPresets = [15, 30, 60, 120, 180, 240];

String _presetLabel(int minutes) {
  if (minutes < 60) return "${minutes}m";
  if (minutes % 60 == 0) return "${minutes ~/ 60}h";
  return formatMinutes(minutes);
}

bool _isCustomLimitMinutes(int minutes) => !_kLimitPresets.contains(minutes);

Future<int?> _askCustomLimitMinutes({
  required BuildContext context,
  required int initialMinutes,
}) async {
  final controller = TextEditingController(text: initialMinutes.toString());
  try {
    return await showDialog<int>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (ctx) {
        var errorText = "";
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text("Custom daily limit"),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Minutes per day",
                hintText:
                    "${AppScreenTimeLimit.minMinutes}–${AppScreenTimeLimit.maxMinutes}",
                errorText: errorText.isEmpty ? null : errorText,
              ),
              onSubmitted: (_) {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null ||
                    parsed < AppScreenTimeLimit.minMinutes ||
                    parsed > AppScreenTimeLimit.maxMinutes) {
                  setDialogState(() {
                    errorText =
                        "Enter ${AppScreenTimeLimit.minMinutes}–${AppScreenTimeLimit.maxMinutes} minutes";
                  });
                  return;
                }
                Navigator.pop(
                  ctx,
                  parsed.clamp(
                    AppScreenTimeLimit.minMinutes,
                    AppScreenTimeLimit.maxMinutes,
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: () {
                  final parsed = int.tryParse(controller.text.trim());
                  if (parsed == null ||
                      parsed < AppScreenTimeLimit.minMinutes ||
                      parsed > AppScreenTimeLimit.maxMinutes) {
                    setDialogState(() {
                      errorText =
                          "Enter ${AppScreenTimeLimit.minMinutes}–${AppScreenTimeLimit.maxMinutes} minutes";
                    });
                    return;
                  }
                  Navigator.pop(
                    ctx,
                    parsed.clamp(
                      AppScreenTimeLimit.minMinutes,
                      AppScreenTimeLimit.maxMinutes,
                    ),
                  );
                },
                child: const Text("Apply"),
              ),
            ],
          ),
        );
      },
    );
  } finally {
    controller.dispose();
  }
}

class _LimitsSection extends ConsumerWidget {
  const _LimitsSection({
    required this.usage,
    required this.limitsState,
  });

  final UsageState usage;
  final ScreenTimeLimitsState limitsState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final limitsNotifier = ref.read(screenTimeLimitsProvider.notifier);
    final usageStatsService = ref.read(usageStatsServiceProvider);

    final todayUsages = usage.today?.appUsages ?? const <AppUsageModel>[];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.timer_outlined, color: theme.colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Daily app limits",
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        "Gentle alerts when you reach your cap",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!usage.hasPermission) const Icon(Icons.lock_outline, size: 18),
              ],
            ),
            const SizedBox(height: 14),
            if (limitsState.loading) ...[
              const LinearProgressIndicator(minHeight: 3),
              const SizedBox(height: 10),
              const Text("Loading your limits..."),
            ] else if (limitsState.limits.isEmpty) ...[
              _EmptyLimitsHint(onAdd: usage.hasPermission
                  ? () => _openAddLimitSheet(
                        context: context,
                        usageStatsService: usageStatsService,
                        limitsNotifier: limitsNotifier,
                        todayUsages: todayUsages,
                      )
                  : null),
            ] else ...[
              ...limitsState.limits.values.map(
                (limit) => _LimitCard(
                  limit: limit,
                  usedTodayMinutes: _usedMinutesFor(
                    appUsages: todayUsages,
                    packageName: limit.packageName,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: usage.hasPermission
                    ? () => _openAddLimitSheet(
                          context: context,
                          usageStatsService: usageStatsService,
                          limitsNotifier: limitsNotifier,
                          todayUsages: todayUsages,
                        )
                    : null,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text("Add another limit"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Future<void> _openAddLimitSheet({
    required BuildContext context,
    required UsageStatsService usageStatsService,
    required ScreenTimeLimitsNotifier limitsNotifier,
    required List<AppUsageModel> todayUsages,
  }) async {
    try {
      final installedApps = await usageStatsService.listInstalledApps();
      if (!context.mounted) return;
      await _showAddLimitSheet(
        context: context,
        installedApps: installedApps,
        todayAppUsages: todayUsages,
        onSave: (pkg, name, presetMinutes) async {
          await limitsNotifier.upsertLimit(
            packageName: pkg,
            displayName: name,
            limitMinutesPerDay: presetMinutes,
            notifyWhenExceeded: true,
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  static int _usedMinutesFor({
    required List<AppUsageModel> appUsages,
    required String packageName,
  }) {
    for (final a in appUsages) {
      if (a.packageName == packageName) return a.usageTime;
    }
    return 0;
  }

  static Future<void> _showAddLimitSheet({
    required BuildContext context,
    required List<InstalledAppModel> installedApps,
    required List<AppUsageModel> todayAppUsages,
    required Future<void> Function(
      String packageName,
      String displayName,
      int presetMinutes,
    )
        onSave,
  }) async {
    if (installedApps.isEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No apps found"),
          content: const Text(
            "Could not load installed apps right now. Try again in a moment.",
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
          ],
        ),
      );
      return;
    }

    var search = "";
    String selectedPkg = installedApps.first.packageName;
    String selectedName = installedApps.first.appName;
    var selectedPreset = 30;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setState) {
            final theme = Theme.of(ctx2);
            final filtered = installedApps.where((a) {
              if (search.isEmpty) return true;
              return a.appName.toLowerCase().contains(search) ||
                  a.packageName.toLowerCase().contains(search);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx2).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx2).size.height * 0.82,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Set daily limit",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Pick any app on your phone",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: "Search apps",
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() => search = v.trim().toLowerCase()),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final a = filtered[i];
                          final selected = a.packageName == selectedPkg;
                          final used = _usedMinutesFor(
                            appUsages: todayAppUsages,
                            packageName: a.packageName,
                          );
                          return Material(
                            color: selected
                                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => setState(() {
                                selectedPkg = a.packageName;
                                selectedName = a.appName;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    AppIconWidget(packageName: a.packageName, size: 48),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            a.appName,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            used > 0
                                                ? "${formatMinutes(used)} used today"
                                                : a.category,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected)
                                      Icon(Icons.check_circle, color: theme.colorScheme.primary)
                                    else
                                      Icon(Icons.circle_outlined,
                                          color: theme.colorScheme.outline),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _kGreen.withValues(alpha: 0.12),
                            _kGreenDark.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AppIconWidget(packageName: selectedPkg, size: 40),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Daily limit",
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._kLimitPresets.map((m) {
                                final selected = m == selectedPreset;
                                return FilterChip(
                                  label: Text(_presetLabel(m)),
                                  selected: selected,
                                  showCheckmark: true,
                                  onSelected: (_) => setState(() => selectedPreset = m),
                                );
                              }),
                              FilterChip(
                                avatar: const Icon(Icons.edit_outlined, size: 16),
                                label: Text(
                                  _isCustomLimitMinutes(selectedPreset)
                                      ? "Custom (${_presetLabel(selectedPreset)})"
                                      : "Custom",
                                ),
                                selected: _isCustomLimitMinutes(selectedPreset),
                                showCheckmark: true,
                                onSelected: (_) async {
                                  final custom = await _askCustomLimitMinutes(
                                    context: context,
                                    initialMinutes: selectedPreset,
                                  );
                                  if (custom == null) return;
                                  setState(() => selectedPreset = custom);
                                },
                              ),
                            ],
                          ),
                          if (_isCustomLimitMinutes(selectedPreset))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                "Selected: ${_presetLabel(selectedPreset)} per day",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: _kGreenDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        await onSave(selectedPkg, selectedName, selectedPreset);
                        if (ctx2.mounted) Navigator.pop(ctx2);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _kGreenDark,
                      ),
                      child: const Text("Save limit"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyLimitsHint extends StatelessWidget {
  const _EmptyLimitsHint({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "No limits yet",
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            "Choose any app and set a daily cap. We'll send a gentle nudge when you reach it.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text("Add limit"),
          ),
        ],
      ),
    );
  }
}

class _LimitCard extends ConsumerWidget {
  const _LimitCard({
    required this.limit,
    required this.usedTodayMinutes,
  });

  final AppScreenTimeLimit limit;
  final int usedTodayMinutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final limitsNotifier = ref.read(screenTimeLimitsProvider.notifier);
    final name = limit.displayName.isNotEmpty ? limit.displayName : limit.packageName;

    final progress = limit.limitMinutesPerDay <= 0
        ? 0.0
        : (usedTodayMinutes / limit.limitMinutesPerDay).clamp(0.0, 1.0);
    final over = usedTodayMinutes >= limit.limitMinutesPerDay;
    final pct = (progress * 100).round();
    final accent = over ? const Color(0xFFE11D48) : _kGreenDark;
    final remaining = (limit.limitMinutesPerDay - usedTodayMinutes).clamp(0, 99999);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: over
              ? const Color(0xFFE11D48).withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIconWidget(packageName: limit.packageName, size: 52, borderRadius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        over
                            ? "Limit reached · ${formatMinutes(usedTodayMinutes)} today"
                            : "${formatMinutes(usedTodayMinutes)} used · ${formatMinutes(remaining)} left",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$pct%",
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: accent,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "0",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  "Limit ${_presetLabel(limit.limitMinutesPerDay)}",
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "Adjust limit",
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._kLimitPresets.map((m) {
                    final selected = m == limit.limitMinutesPerDay;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_presetLabel(m)),
                        selected: selected,
                        showCheckmark: true,
                        onSelected: (_) async {
                          await limitsNotifier.upsertLimit(
                            packageName: limit.packageName,
                            displayName: limit.displayName,
                            limitMinutesPerDay: m,
                            notifyWhenExceeded: limit.notifyWhenExceeded,
                          );
                        },
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                        _isCustomLimitMinutes(limit.limitMinutesPerDay)
                            ? "Custom (${_presetLabel(limit.limitMinutesPerDay)})"
                            : "Custom",
                      ),
                      selected: _isCustomLimitMinutes(limit.limitMinutesPerDay),
                      showCheckmark: true,
                      onSelected: (_) async {
                        final custom = await _askCustomLimitMinutes(
                          context: context,
                          initialMinutes: limit.limitMinutesPerDay,
                        );
                        if (custom == null) return;
                        await limitsNotifier.upsertLimit(
                          packageName: limit.packageName,
                          displayName: limit.displayName,
                          limitMinutesPerDay: custom,
                          notifyWhenExceeded: limit.notifyWhenExceeded,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                secondary: Icon(
                  limit.notifyWhenExceeded ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                title: const Text("Gentle alerts"),
                subtitle: const Text("One friendly nudge per day when limit is hit"),
                value: limit.notifyWhenExceeded,
                onChanged: (v) async {
                  final ok = await limitsNotifier.setNotificationsEnabled(
                    packageName: limit.packageName,
                    enabled: v,
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Couldn't enable alerts — notification permission required.",
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => limitsNotifier.removeLimit(limit.packageName),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text("Remove"),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreenTimeHeader extends StatelessWidget {
  const _ScreenTimeHeader({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Screen time",
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const AccountAvatarButton(),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          metrics.hasUsageData
              ? "Usage breakdown, trends, and app details."
              : "Grant usage access under More → Account, or use dev spoof there.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Usage access required",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              "Android needs Usage Access permission to read screen time and app usage. "
              "This is enabled in Android Settings (not a standard in-app popup).",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => ref.read(usageProvider.notifier).openUsageSettings(),
              icon: const Icon(Icons.settings),
              label: const Text("Grant permission (opens Settings)"),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.read(usageProvider.notifier).checkPermission(),
              child: const Text("I granted permission"),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayHeroCard extends StatelessWidget {
  const _TodayHeroCard({required this.metrics});

  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const goal = DashboardMetricsService.dailyScreenTimeGoalMinutes;
    final progress = metrics.screenProgress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGreen, _kGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatMinutes(metrics.screenMinutes),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metrics.screenTimeSubtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Daily goal: ${formatMinutes(goal)}",
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });

  final String label;
  final int score;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.labelMedium),
            Text(
              "$score",
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.18),
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.apps});

  final List<AppUsageModel> apps;

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) return const SizedBox.shrink();

    var social = 0, productive = 0, game = 0, other = 0;
    for (final a in apps) {
      final c = a.category.toLowerCase();
      if (c.contains("social")) {
        social += a.usageTime;
      } else if (c.contains("productivity") || c.contains("education")) {
        productive += a.usageTime;
      } else if (c.contains("game")) {
        game += a.usageTime;
      } else {
        other += a.usageTime;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "By category",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CategoryChip(label: "Social", minutes: social, color: const Color(0xFFEA580C)),
                _CategoryChip(label: "Productive", minutes: productive, color: const Color(0xFF16A34A)),
                _CategoryChip(label: "Games", minutes: game, color: const Color(0xFF7C3AED)),
                _CategoryChip(label: "Other", minutes: other, color: const Color(0xFF64748B)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.minutes,
    required this.color,
  });

  final String label;
  final int minutes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        "$label · ${formatMinutes(minutes)}",
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
