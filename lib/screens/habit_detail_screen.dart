import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:health/health.dart";
import "package:life_pattern_tracker/data/habit_log_presets.dart";
import "package:life_pattern_tracker/models/habit_tracker_habit.dart";
import "package:life_pattern_tracker/models/habit_log_preset.dart";
import "package:life_pattern_tracker/models/mood_day.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";
import "package:life_pattern_tracker/models/today_log_group.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/insights_provider.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";
import "package:life_pattern_tracker/utils/app_log.dart";
import "package:life_pattern_tracker/utils/habit_log_details_formatter.dart";
import "package:life_pattern_tracker/utils/week_calendar.dart";

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  final Set<String> _dismissedInsightIds = <String>{};

  static const Map<String, String> _habitToPresetId = {
    "sleep": "sleep",
    "exercise": "workout",
    "water": "water",
    "read": "read",
    "meditate": "meditation",
    "mood": "mood",
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitTrackerProvider);
    final notifier = ref.read(habitTrackerProvider.notifier);
    HabitTrackerHabit? habit;
    for (final h in state.habits) {
      if (h.id == widget.habitId) {
        habit = h;
        break;
      }
    }
    if (habit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Habit details")),
        body: const Center(child: Text("Habit not found.")),
      );
    }
    final selectedHabit = habit;
    final logs = HabitTrackerNotifier.groupLogs(state.todayLogs)
        .where((g) => HabitTrackerNotifier.mapLogKeyToHabitId(g.activityKey) == selectedHabit.id)
        .toList();
    final insights = ref.watch(insightsProvider).insights;
    final relevantInsights = _buildRelevantInsights(
      habit: selectedHabit,
      aiTips: insights.aiTips,
      recommendations: insights.recommendations.map((r) => "${r.title}. ${r.description}"),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(selectedHabit.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () => _showQuickAddSheet(context, selectedHabit),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Add"),
            ),
          ),
        ],
      ),
      body: AppGradientBackground(
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeroHabitCard(habit: selectedHabit),
          const SizedBox(height: 14),
          _ConnectedMetricsCard(
            habit: selectedHabit,
            allLogs: state.logs,
            moodDays: state.moodDays,
          ),
          const SizedBox(height: 14),
          _WeeklyStatusCard(
            habit: selectedHabit,
            onToggleDay: (dayIndex) => notifier.toggleHabitDay(selectedHabit.id, dayIndex),
          ),
          const SizedBox(height: 14),
          _HabitTrendCard(
            habit: selectedHabit,
            allLogs: state.logs,
          ),
          const SizedBox(height: 14),
          _HabitLogsCard(logs: logs),
          const SizedBox(height: 14),
          _AiInsightMessagesCard(
            messages: relevantInsights,
            dismissedIds: _dismissedInsightIds,
            onDismiss: (id) => setState(() => _dismissedInsightIds.add(id)),
          ),
        ],
      ),
      ),
    );
  }

  List<_HabitInsightMessage> _buildRelevantInsights({
    required HabitTrackerHabit habit,
    required Iterable<dynamic> aiTips,
    required Iterable<String> recommendations,
  }) {
    final lines = <String>[];
    for (final tip in aiTips) {
      final title = tip.title?.toString() ?? "";
      final desc = tip.description?.toString() ?? "";
      final joined = "$title. $desc".trim();
      if (joined.isNotEmpty) lines.add(joined);
    }
    lines.addAll(recommendations);
    final filtered = <_HabitInsightMessage>[];
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i];
      if (_isRelevantInsight(habit.id, text)) {
        filtered.add(_HabitInsightMessage(id: "${habit.id}-$i-$text", text: text));
      }
    }
    if (filtered.isEmpty) {
      filtered.add(
        _HabitInsightMessage(
          id: "${habit.id}-fallback",
          text: "Consistency beats intensity. Keep checking in daily for ${habit.name.toLowerCase()}.",
        ),
      );
    }
    return filtered.take(4).toList();
  }

  bool _isRelevantInsight(String habitId, String text) {
    final t = text.toLowerCase();
    switch (habitId) {
      case "sleep":
        return t.contains("sleep") || t.contains("bed") || t.contains("night");
      case "exercise":
        return t.contains("exercise") || t.contains("activity") || t.contains("steps");
      case "water":
        return t.contains("water") || t.contains("hydrat");
      case "read":
        return t.contains("read") || t.contains("focus");
      case "meditate":
        return t.contains("mood") || t.contains("stress") || t.contains("mental") || t.contains("focus");
      case "mood":
        return t.contains("mood") || t.contains("mental") || t.contains("wellness");
      default:
        return true;
    }
  }

  void _showQuickAddSheet(BuildContext context, HabitTrackerHabit habit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _QuickHabitAddSheet(
        habit: habit,
        mappedPresetId: _habitToPresetId[habit.id],
      ),
    );
  }
}

class _HabitInsightMessage {
  const _HabitInsightMessage({required this.id, required this.text});

  final String id;
  final String text;
}

class _AiInsightMessagesCard extends StatelessWidget {
  const _AiInsightMessagesCard({
    required this.messages,
    required this.dismissedIds,
    required this.onDismiss,
  });

  final List<_HabitInsightMessage> messages;
  final Set<String> dismissedIds;
  final void Function(String id) onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final panel = AppColors.subtlePanel(theme.brightness);
    final visible = messages.where((m) => !dismissedIds.contains(m.id)).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "AI insights",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            ...visible.map(
              (m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                decoration: BoxDecoration(
                  color: panel.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: panel.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.auto_awesome, size: 16, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        m.text,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onDismiss(m.id),
                      icon: const Icon(Icons.close, size: 16),
                      splashRadius: 16,
                      visualDensity: VisualDensity.compact,
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

class _QuickHabitAddSheet extends ConsumerStatefulWidget {
  const _QuickHabitAddSheet({
    required this.habit,
    required this.mappedPresetId,
  });

  final HabitTrackerHabit habit;
  final String? mappedPresetId;

  @override
  ConsumerState<_QuickHabitAddSheet> createState() => _QuickHabitAddSheetState();
}

class _QuickHabitAddSheetState extends ConsumerState<_QuickHabitAddSheet> {
  final TextEditingController _detailsCtrl = TextEditingController();
  final TextEditingController _timeCtrl = TextEditingController();
  late final HabitLogPreset? _preset;
  late int _selectedDayIndex;

  @override
  void initState() {
    super.initState();
    _selectedDayIndex = WeekCalendar.todayWeekIndex;
    HabitLogPreset? p;
    for (final candidate in HabitLogPresets.all) {
      if (candidate.id == widget.mappedPresetId) {
        p = candidate;
        break;
      }
    }
    _preset = p;
  }

  @override
  void dispose() {
    _detailsCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  bool get _needsTime => !(_preset?.timeOptional ?? false);

  HabitLogAmountUnit get _amountUnit => _preset?.amountUnit ?? HabitLogAmountUnit.freeText;

  String _dateKeyForWeekIndex(int index) {
    final day = WeekCalendar.weekStart.add(Duration(days: index.clamp(0, 6)));
    final y = day.year.toString().padLeft(4, "0");
    final m = day.month.toString().padLeft(2, "0");
    final d = day.day.toString().padLeft(2, "0");
    return "$y-$m-$d";
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      _timeCtrl.text = picked.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = WeekCalendar.currentWeekDayLabels();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Add missed entry",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              "Log ${widget.habit.name.toLowerCase()} for a specific day.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Which day?",
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(labels.length, (i) {
                return ChoiceChip(
                  label: Text(labels[i]),
                  selected: _selectedDayIndex == i,
                  onSelected: (_) => setState(() => _selectedDayIndex = i),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsCtrl,
              keyboardType: _amountUnit == HabitLogAmountUnit.freeText
                  ? TextInputType.text
                  : const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: HabitLogDetailsFormatter.amountLabel(_amountUnit),
                hintText: HabitLogDetailsFormatter.amountHint(_amountUnit),
                suffixText: _amountUnit == HabitLogAmountUnit.minutes
                    ? "min"
                    : _amountUnit == HabitLogAmountUnit.glasses
                        ? "glasses"
                        : _amountUnit == HabitLogAmountUnit.hours
                            ? "hrs"
                            : null,
              ),
            ),
            if (_needsTime) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _timeCtrl,
                readOnly: true,
                onTap: _pickTime,
                decoration: InputDecoration(
                  labelText: "Time",
                  hintText: "e.g. 7:30 AM",
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    tooltip: "Pick time",
                    onPressed: _pickTime,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                final notifier = ref.read(habitTrackerProvider.notifier);
                final details = _detailsCtrl.text.trim();
                final time = _timeCtrl.text.trim();
                if (_needsTime && time.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please add time for this entry.")),
                  );
                  return;
                }
                final dateKey = _dateKeyForWeekIndex(_selectedDayIndex);
                if (_preset != null) {
                  notifier.addLogSessionFromPreset(
                    preset: _preset,
                    timeLabel: time,
                    subtitle: details,
                    dateKey: dateKey,
                  );
                } else {
                  notifier.addLogSession(
                    activityKey: HabitTrackerNotifier.customActivityKey(widget.habit.name),
                    title: widget.habit.name,
                    subtitle: details,
                    emoji: widget.habit.emoji,
                    timeLabel: time,
                    amountUnit: HabitLogAmountUnit.freeText,
                    dateKey: dateKey,
                  );
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text("Save entry"),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroHabitCard extends StatelessWidget {
  const _HeroHabitCard({required this.habit});

  final HabitTrackerHabit habit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doneThisWeek = habit.completedDays;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(habit.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  habit.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                "${habit.percent}",
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: habit.percent / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: const Color(0xFF60A5FA),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _HeroStat(label: "Completed", value: "$doneThisWeek/7"),
              const SizedBox(width: 12),
              _HeroStat(label: "Streak", value: "${habit.currentStreak()}d"),
              const SizedBox(width: 12),
              _HeroStat(label: "Remaining", value: "${7 - doneThisWeek}"),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyStatusCard extends StatelessWidget {
  const _WeeklyStatusCard({
    required this.habit,
    this.onToggleDay,
  });

  final HabitTrackerHabit habit;
  final void Function(int dayIndex)? onToggleDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = HabitTrackerHabit.weekDayLabels();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "This week",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              onToggleDay != null ? "Tap a day to update progress" : "Weekly completion status",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(7, (i) {
                final done = habit.weekCompleted[i];
                final isToday = i == WeekCalendar.todayWeekIndex;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: onToggleDay == null ? null : () => onToggleDay!(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 26,
                            decoration: BoxDecoration(
                              color: done
                                  ? const Color(0xFF3B82F6)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isToday
                                  ? Border.all(color: const Color(0xFF2563EB), width: 2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: done
                                ? const Icon(Icons.check, size: 15, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[i],
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            _FactorBar(
              label: "Consistency",
              valueText: "${habit.percent}%",
              progress: habit.percent / 100,
              barColor: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 10),
            Text(
              "Current streak: ${habit.currentStreak()} day(s)",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _TrendRange { week, month }

class _HabitTrendCard extends StatefulWidget {
  const _HabitTrendCard({
    required this.habit,
    required this.allLogs,
  });

  final HabitTrackerHabit habit;
  final List<TodayLogEntry> allLogs;

  @override
  State<_HabitTrendCard> createState() => _HabitTrendCardState();
}

class _HabitTrendCardState extends State<_HabitTrendCard> {
  _TrendRange _range = _TrendRange.week;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bars = _buildBars(
      habit: widget.habit,
      allLogs: widget.allLogs,
      range: _range,
    );
    final maxY = bars.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    final safeMax = maxY <= 0 ? 1.0 : maxY;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Trends",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                SegmentedButton<_TrendRange>(
                  segments: const [
                    ButtonSegment(value: _TrendRange.week, label: Text("Week")),
                    ButtonSegment(value: _TrendRange.month, label: Text("Month")),
                  ],
                  selected: {_range},
                  onSelectionChanged: (s) => setState(() => _range = s.first),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final b in bars)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: (b.value / safeMax) * 130,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _range == _TrendRange.week
                  ? "Last 7 days"
                  : "Last 30 days (grouped by week)",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<_TrendBar> _buildBars({
    required HabitTrackerHabit habit,
    required List<TodayLogEntry> allLogs,
    required _TrendRange range,
  }) {
    final now = DateTime.now();
    final linkedLogs = allLogs.where((e) {
      return HabitTrackerNotifier.mapLogKeyToHabitId(e.activityKey) == habit.id;
    }).toList();

    double valueFor(TodayLogEntry e) {
      final unit = HabitLogDetailsFormatter.unitForActivityKey(e.activityKey, e.title);
      switch (unit) {
        case HabitLogAmountUnit.minutes:
          return HabitLogDetailsFormatter.minutesFromSubtitle(e.subtitle).toDouble();
        case HabitLogAmountUnit.glasses:
          return HabitLogDetailsFormatter.glassesFromSubtitle(e.subtitle).toDouble();
        case HabitLogAmountUnit.hours:
          return HabitLogDetailsFormatter.hoursFromSubtitle(e.subtitle);
        case HabitLogAmountUnit.freeText:
          return 1;
      }
    }

    if (range == _TrendRange.week) {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      final bars = <_TrendBar>[];
      for (var i = 0; i < 7; i++) {
        final day = start.add(Duration(days: i));
        final dateKey = _dateKey(day);
        var v = 0.0;
        for (final e in linkedLogs) {
          if (e.dateKey == dateKey) v += valueFor(e);
        }
        final weekIndex = WeekCalendar.weekIndexForDateKey(dateKey);
        if (weekIndex >= 0 && weekIndex <= 6 && habit.weekCompleted[weekIndex] && v == 0) {
          v = 1;
        }
        bars.add(_TrendBar(label: _shortWeekday(day.weekday), value: v));
      }
      return bars;
    }

    final monthStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
    final grouped = List<double>.filled(5, 0);
    for (var i = 0; i < 30; i++) {
      final day = monthStart.add(Duration(days: i));
      final bucket = (i / 6).floor().clamp(0, 4);
      final dateKey = _dateKey(day);
      for (final e in linkedLogs) {
        if (e.dateKey == dateKey) grouped[bucket] += valueFor(e);
      }
      final weekIndex = WeekCalendar.weekIndexForDateKey(dateKey);
      if (weekIndex >= 0 && weekIndex <= 6 && habit.weekCompleted[weekIndex]) {
        grouped[bucket] += 1;
      }
    }
    return List.generate(5, (i) => _TrendBar(label: "W${i + 1}", value: grouped[i]));
  }

  static String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, "0");
    final m = d.month.toString().padLeft(2, "0");
    final day = d.day.toString().padLeft(2, "0");
    return "$y-$m-$day";
  }

  static String _shortWeekday(int weekday) {
    const names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return names[(weekday - 1).clamp(0, 6)];
  }
}

class _TrendBar {
  const _TrendBar({required this.label, required this.value});
  final String label;
  final double value;
}

class _HabitLogsCard extends StatelessWidget {
  const _HabitLogsCard({required this.logs});

  final List<TodayLogGroup> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's logs",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (logs.isEmpty)
              Text(
                "No logs yet for this habit today.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...logs.map(
                (g) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(g.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                g.totalSubtitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${g.sessions.length}",
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedMetricsCard extends StatefulWidget {
  const _ConnectedMetricsCard({
    required this.habit,
    required this.allLogs,
    required this.moodDays,
  });

  final HabitTrackerHabit habit;
  final List<TodayLogEntry> allLogs;
  final List<MoodDay> moodDays;

  @override
  State<_ConnectedMetricsCard> createState() => _ConnectedMetricsCardState();
}

class _ConnectedMetricsCardState extends State<_ConnectedMetricsCard> {
  bool _loading = false;
  String? _error;
  int? _stepsToday;
  double? _sleepHoursLastNight;

  @override
  void initState() {
    super.initState();
    _loadIfSupported();
  }

  bool get _supportsImport => widget.habit.id == "exercise" || widget.habit.id == "sleep";

  double _habitTotalFromLogs() {
    var total = 0.0;
    for (final e in widget.allLogs) {
      if (HabitTrackerNotifier.mapLogKeyToHabitId(e.activityKey) != widget.habit.id) continue;
      final unit = HabitLogDetailsFormatter.unitForActivityKey(e.activityKey, e.title);
      switch (unit) {
        case HabitLogAmountUnit.minutes:
          total += HabitLogDetailsFormatter.minutesFromSubtitle(e.subtitle);
        case HabitLogAmountUnit.glasses:
          total += HabitLogDetailsFormatter.glassesFromSubtitle(e.subtitle);
        case HabitLogAmountUnit.hours:
          total += HabitLogDetailsFormatter.hoursFromSubtitle(e.subtitle);
        case HabitLogAmountUnit.freeText:
          total += 1;
      }
    }
    return total;
  }

  Future<void> _loadIfSupported() async {
    if (!_supportsImport || !Platform.isAndroid) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final health = Health();
      await health.configure();
      final reads = widget.habit.id == "sleep"
          ? const [HealthDataType.SLEEP_SESSION, HealthDataType.SLEEP_ASLEEP]
          : const [HealthDataType.STEPS];
      final permissions = List<HealthDataAccess>.filled(reads.length, HealthDataAccess.READ);
      final has = await health.hasPermissions(reads, permissions: permissions);
      if (has != true) {
        final granted = await health.requestAuthorization(reads, permissions: permissions);
        if (!granted) {
          setState(() {
            _loading = false;
            _error = "Permission not granted.";
          });
          return;
        }
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      if (widget.habit.id == "exercise") {
        _stepsToday = await health.getTotalStepsInInterval(startOfDay, now);
      } else {
        final sleepStart = startOfDay.subtract(const Duration(hours: 18));
        var points = await health.getHealthDataFromTypes(
          types: const [HealthDataType.SLEEP_SESSION],
          startTime: sleepStart,
          endTime: now,
        );
        if (points.isEmpty) {
          points = await health.getHealthDataFromTypes(
            types: const [HealthDataType.SLEEP_ASLEEP],
            startTime: sleepStart,
            endTime: now,
          );
        }
        double hours = 0;
        for (final p in points) {
          hours += p.dateTo.difference(p.dateFrom).inMinutes / 60.0;
        }
        _sleepHoursLastNight = hours > 0 ? hours : null;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e, st) {
      AppLog.e("Habit import read failed", error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is MissingPluginException
            ? "Plugin unavailable. Rebuild app and try again."
            : "Could not load connected metrics.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Connected metrics",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (!_supportsImport)
              _buildHabitNativeMetrics(theme)
            else if (!Platform.isAndroid)
              Text(
                "Connected metrics are available on Android only.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else if (_loading)
              const LinearProgressIndicator(minHeight: 3)
            else if (_error != null)
              Text(_error!, style: TextStyle(color: theme.colorScheme.error))
            else if (widget.habit.id == "exercise")
              _MetricPanel(
                title: "Steps today",
                value: _stepsToday == null ? "—" : "$_stepsToday",
                hint: "Mapped to your Exercise habit",
              )
            else
              _MetricPanel(
                title: "Sleep duration",
                value: _sleepHoursLastNight == null
                    ? "—"
                    : "${_sleepHoursLastNight!.toStringAsFixed(1)} h",
                hint: "Mapped to your Sleep habit",
              ),
            if (_supportsImport && !_loading && _error == null) ...[
              const SizedBox(height: 12),
              _FactorBar(
                label: widget.habit.id == "exercise" ? "Goal progress" : "Target progress",
                valueText: widget.habit.id == "exercise"
                    ? "${((_stepsToday ?? 0) / 8000 * 100).clamp(0, 100).round()}%"
                    : "${(((_sleepHoursLastNight ?? 0) / 8) * 100).clamp(0, 100).round()}%",
                progress: widget.habit.id == "exercise"
                    ? ((_stepsToday ?? 0) / 8000).clamp(0.0, 1.0)
                    : ((_sleepHoursLastNight ?? 0) / 8).clamp(0.0, 1.0),
                barColor: const Color(0xFF2563EB),
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHabitNativeMetrics(ThemeData theme) {
    final total = _habitTotalFromLogs();
    switch (widget.habit.id) {
      case "water":
        final glasses = total.round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricPanel(
              title: "Water today",
              value: "$glasses glasses",
              hint: "From your habit log entries",
            ),
            const SizedBox(height: 12),
            _FactorBar(
              label: "Hydration target",
              valueText: "${((glasses / 8) * 100).clamp(0, 100).round()}%",
              progress: (glasses / 8).clamp(0.0, 1.0),
              barColor: const Color(0xFF06B6D4),
            ),
          ],
        );
      case "read":
        final hours = total;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricPanel(
              title: "Reading today",
              value: "${hours.toStringAsFixed(hours >= 1 ? 1 : 2)} h",
              hint: "From your reading log entries",
            ),
            const SizedBox(height: 12),
            _FactorBar(
              label: "Daily reading target",
              valueText: "${((hours / 1.5) * 100).clamp(0, 100).round()}%",
              progress: (hours / 1.5).clamp(0.0, 1.0),
              barColor: const Color(0xFF8B5CF6),
            ),
          ],
        );
      case "meditate":
        final minutes = total.round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricPanel(
              title: "Meditation today",
              value: "$minutes min",
              hint: "From your mindfulness log entries",
            ),
            const SizedBox(height: 12),
            _FactorBar(
              label: "Mindfulness target",
              valueText: "${((minutes / 20) * 100).clamp(0, 100).round()}%",
              progress: (minutes / 20).clamp(0.0, 1.0),
              barColor: const Color(0xFF7C3AED),
            ),
          ],
        );
      case "mood":
        double avg = 0;
        var count = 0;
        for (final d in widget.moodDays) {
          final s = (d.score as num?)?.toDouble() ?? 0;
          if (s > 0) {
            avg += s;
            count++;
          }
        }
        if (count > 0) avg /= count;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricPanel(
              title: "Mood average",
              value: count == 0 ? "—" : "${avg.toStringAsFixed(1)} / 10",
              hint: "Based on this week's mood check-ins",
            ),
            const SizedBox(height: 12),
            _FactorBar(
              label: "Check-in consistency",
              valueText: "${widget.habit.percent}%",
              progress: widget.habit.percent / 100,
              barColor: const Color(0xFFEC4899),
            ),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MetricPanel(
              title: "Habit activity",
              value: "${total.round()} entries",
              hint: "From your current-week habit logs",
            ),
            const SizedBox(height: 12),
            _FactorBar(
              label: "Consistency",
              valueText: "${widget.habit.percent}%",
              progress: widget.habit.percent / 100,
              barColor: const Color(0xFF2563EB),
            ),
          ],
        );
    }
  }
}

class _MetricPanel extends StatelessWidget {
  const _MetricPanel({
    required this.title,
    required this.value,
    required this.hint,
  });

  final String title;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.insights, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _FactorBar extends StatelessWidget {
  const _FactorBar({
    required this.label,
    required this.valueText,
    required this.progress,
    required this.barColor,
  });

  final String label;
  final String valueText;
  final double progress;
  final Color barColor;

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
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              valueText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: barColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            color: barColor,
          ),
        ),
      ],
    );
  }
}
