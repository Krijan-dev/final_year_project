import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/data/habit_log_presets.dart";
import "package:life_pattern_tracker/data/mood_types.dart";
import "package:life_pattern_tracker/models/mood_type.dart";
import "package:life_pattern_tracker/models/habit_log_preset.dart";
import "package:life_pattern_tracker/models/habit_tracker_habit.dart";
import "package:life_pattern_tracker/models/mood_day.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";
import "package:life_pattern_tracker/models/today_log_group.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/screens/habit_detail_screen.dart";
import "package:life_pattern_tracker/utils/habit_log_details_formatter.dart";
import "package:life_pattern_tracker/utils/week_calendar.dart";

const Color _kHabitGreen = Color(0xFF22C55E);
const Color _kHabitGreenDark = Color(0xFF16A34A);
const Color _kDayIncomplete = Color(0xFFE5E7EB);
const Color _kMoodPink = Color(0xFFF9A8D4);
const Color _kAddBlue = Color(0xFF2563EB);

class HabitScreen extends ConsumerWidget {
  const HabitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(habitTrackerProvider);
    final notifier = ref.read(habitTrackerProvider.notifier);

    if (!state.ready) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: notifier.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _HabitHeader(),
          const SizedBox(height: 16),
          _WeeklyProgressCard(
            percent: state.weeklyProgressPercent,
            message: state.weeklyProgressMessage,
          ),
          const SizedBox(height: 16),
          _ThisWeeksHabitsCard(
            habits: state.habits,
            dayLabels: HabitTrackerHabit.weekDayLabels(),
            onToggleDay: notifier.toggleHabitDay,
            onOpenHabit: (habitId) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HabitDetailScreen(habitId: habitId),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _MoodThisWeekCard(
            days: state.moodDays,
            average: state.averageMood,
            onDayTap: notifier.setMood,
          ),
          const SizedBox(height: 16),
          _TodaysLogCard(
            logs: state.todayLogs,
            onAdd: () => _showAddLogSheet(context, ref),
          ),
        ],
      ),
    );
  }

  static void _showAddLogSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddLogSheet(scaffoldContext: context),
    );
  }
}

class _AddLogSheet extends ConsumerStatefulWidget {
  const _AddLogSheet({required this.scaffoldContext});

  final BuildContext scaffoldContext;

  @override
  ConsumerState<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends ConsumerState<_AddLogSheet> {
  HabitLogPreset? _selectedPreset;
  bool _customMode = false;
  final _titleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _selectPreset(HabitLogPreset preset) {
    setState(() {
      _customMode = false;
      _selectedPreset = preset;
      _titleCtrl.clear();
    });
    _clearSessionFields();
  }

  void _selectCustom() {
    setState(() {
      _customMode = true;
      _selectedPreset = null;
    });
    _clearSessionFields();
  }

  HabitLogAmountUnit get _currentAmountUnit {
    if (_customMode) {
      final title = _titleCtrl.text.trim();
      if (title.isEmpty) return HabitLogAmountUnit.freeText;
      return HabitLogDetailsFormatter.unitForCustomTitle(title);
    }
    final preset = _selectedPreset;
    if (preset == null) return HabitLogAmountUnit.freeText;
    return preset.amountUnit;
  }

  String? get _activeActivityKey {
    if (_customMode) {
      final title = _titleCtrl.text.trim();
      if (title.isEmpty) return null;
      return HabitTrackerNotifier.customActivityKey(title);
    }
    return _selectedPreset?.id;
  }

  bool get _timeOptional {
    if (_customMode) {
      final title = _titleCtrl.text.trim();
      if (title.isEmpty) return false;
      return HabitLogDetailsFormatter.isTimeOptional(
        HabitTrackerNotifier.customActivityKey(title),
        title,
      );
    }
    return _selectedPreset?.timeOptional ?? false;
  }

  void _clearSessionFields() {
    _timeCtrl.clear();
    _detailsCtrl.clear();
  }

  String? _todayTotalHint(String activityKey, HabitLogAmountUnit unit) {
    final sessions =
        ref.read(habitTrackerProvider.notifier).sessionsForActivityKey(activityKey);
    if (sessions.isEmpty) return null;
    return "Today so far: ${HabitLogDetailsFormatter.summarizeTotal(sessions, unit)}";
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

  void _save() {
    final timeLabel = _timeCtrl.text.trim();
    if (!_timeOptional && timeLabel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a time for this activity"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final notifier = ref.read(habitTrackerProvider.notifier);
    final details = _detailsCtrl.text.trim();

    if (_customMode) {
      final title = _titleCtrl.text.trim();
      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Enter an activity name"),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final key = HabitTrackerNotifier.customActivityKey(title);
      notifier.addLogSession(
        activityKey: key,
        title: title,
        subtitle: details,
        emoji: "✅",
        timeLabel: timeLabel,
        amountUnit: HabitLogDetailsFormatter.unitForCustomTitle(title),
      );
      _finishSave("Added $title");
      return;
    }

    final preset = _selectedPreset;
    if (preset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Choose an activity or use Other activity"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    notifier.addLogSessionFromPreset(
      preset: preset,
      timeLabel: timeLabel,
      subtitle: details,
    );
    _finishSave("Added ${preset.title}");
  }

  void _finishSave(String message) {
    Navigator.pop(context);
    ScaffoldMessenger.of(widget.scaffoldContext).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final logs = ref.watch(habitTrackerProvider).logs;
    final loggedKeys = logs.map((e) => e.activityKey).toSet();

    final selectionLabel = _customMode
        ? (_titleCtrl.text.trim().isEmpty ? "Custom activity" : _titleCtrl.text.trim())
        : _selectedPreset?.title;
    final totalHint = _activeActivityKey != null
        ? _todayTotalHint(_activeActivityKey!, _currentAmountUnit)
        : null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Log activity",
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "Pick an activity and save. Time is optional for water. "
              "Same activity adds to today's total.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final preset in HabitLogPresets.all)
                  _PresetChip(
                    preset: preset,
                    selected: _selectedPreset?.id == preset.id && !_customMode,
                    alreadyLogged: loggedKeys.contains(preset.id),
                    onTap: () => _selectPreset(preset),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _selectCustom,
              icon: Icon(_customMode ? Icons.check_circle : Icons.edit_outlined),
              label: const Text("Other activity…"),
              style: _customMode
                  ? OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                    )
                  : null,
            ),
            if (_customMode) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: "Activity name",
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (selectionLabel != null || _customMode) ...[
              const SizedBox(height: 16),
              if (selectionLabel != null && !_customMode)
                Text(
                  selectionLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (totalHint != null) ...[
                const SizedBox(height: 8),
                Text(
                  totalHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _detailsCtrl,
                keyboardType: _currentAmountUnit == HabitLogAmountUnit.freeText
                    ? TextInputType.text
                    : const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: HabitLogDetailsFormatter.amountLabel(_currentAmountUnit),
                  hintText: HabitLogDetailsFormatter.amountHint(_currentAmountUnit),
                  border: const OutlineInputBorder(),
                  suffixText: _currentAmountUnit == HabitLogAmountUnit.minutes
                      ? "min"
                      : _currentAmountUnit == HabitLogAmountUnit.glasses
                          ? "glasses"
                          : _currentAmountUnit == HabitLogAmountUnit.hours
                              ? "hrs"
                              : null,
                ),
              ),
              if (!_timeOptional) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _timeCtrl,
                  decoration: InputDecoration(
                    labelText: "Time",
                    hintText: "e.g. 7:30 AM",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.schedule),
                      tooltip: "Pick time",
                      onPressed: _pickTime,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _save,
                child: const Text("Add session"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.selected,
    required this.alreadyLogged,
    required this.onTap,
  });

  final HabitLogPreset preset;
  final bool selected;
  final bool alreadyLogged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.45 : 1,
          );

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(preset.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                preset.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? theme.colorScheme.onPrimaryContainer : null,
                ),
              ),
              if (alreadyLogged) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodPickerResult {
  const _MoodPickerResult({required this.moodTypeId, required this.score});

  final String moodTypeId;
  final double score;
}

Future<void> _showMoodPicker(
  BuildContext context,
  int dayIndex,
  MoodDay current,
  void Function({required int dayIndex, required String moodTypeId, double? score}) onSave,
) async {
  final labels = WeekCalendar.currentWeekDayLabels();
  String? selectedId = current.moodTypeId;
  var score = current.score > 0
      ? current.score
      : (selectedId != null ? MoodTypes.byId(selectedId)?.defaultScore ?? 7.0 : 7.0);

  final saved = await showDialog<_MoodPickerResult>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          final selected = selectedId != null ? MoodTypes.byId(selectedId!) : null;
          return AlertDialog(
            title: Text("Log mood — ${labels[dayIndex]}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "How are you feeling?",
                    style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in MoodTypes.all)
                        _MoodTypeChip(
                          type: type,
                          selected: selectedId == type.id,
                          onTap: () => setLocal(() {
                            selectedId = type.id;
                            score = type.defaultScore;
                          }),
                        ),
                    ],
                  ),
                  if (selected != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(selected.emoji, style: const TextStyle(fontSize: 48)),
                          const SizedBox(height: 4),
                          Text(
                            selected.label,
                            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Intensity (optional fine-tune)",
                      style: Theme.of(ctx).textTheme.labelMedium,
                    ),
                    Slider(
                      value: score,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: score.round().toString(),
                      onChanged: (v) => setLocal(() => score = v),
                    ),
                    Text(
                      "${score.round()} / 10",
                      textAlign: TextAlign.center,
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              FilledButton(
                onPressed: selectedId == null
                    ? null
                    : () => Navigator.pop(
                          ctx,
                          _MoodPickerResult(moodTypeId: selectedId!, score: score),
                        ),
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
  if (saved != null) {
    onSave(dayIndex: dayIndex, moodTypeId: saved.moodTypeId, score: saved.score);
  }
}

class _MoodTypeChip extends StatelessWidget {
  const _MoodTypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final MoodType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      selected: selected,
      showCheckmark: false,
      avatar: Text(type.emoji, style: const TextStyle(fontSize: 18)),
      label: Text(type.label),
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        color: selected ? theme.colorScheme.onPrimaryContainer : null,
      ),
    );
  }
}

class _HabitHeader extends StatelessWidget {
  const _HabitHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Habit Tracker",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Build better habits, one day at a time",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({required this.percent, required this.message});

  final int percent;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kHabitGreen, _kHabitGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kHabitGreen.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weekly Progress",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$percent%",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: SizedBox(
                    height: 8,
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      backgroundColor: Colors.black.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ThisWeeksHabitsCard extends StatelessWidget {
  const _ThisWeeksHabitsCard({
    required this.habits,
    required this.dayLabels,
    required this.onToggleDay,
    required this.onOpenHabit,
  });

  final List<HabitTrackerHabit> habits;
  final List<String> dayLabels;
  final void Function(String habitId, int dayIndex) onToggleDay;
  final void Function(String habitId) onOpenHabit;

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
              "This Week's Habits",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...List.generate(habits.length, (i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i == habits.length - 1 ? 0 : 20),
                child: _HabitWeekRow(
                  habit: habits[i],
                  dayLabels: dayLabels,
                  onToggleDay: onToggleDay,
                  onOpenHabit: onOpenHabit,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HabitWeekRow extends StatelessWidget {
  const _HabitWeekRow({
    required this.habit,
    required this.dayLabels,
    required this.onToggleDay,
    required this.onOpenHabit,
  });

  final HabitTrackerHabit habit;
  final List<String> dayLabels;
  final void Function(String habitId, int dayIndex) onToggleDay;
  final void Function(String habitId) onOpenHabit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => onOpenHabit(habit.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: habit.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "${habit.completedDays}/7 days",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  "${habit.percent}%",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: _kHabitGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
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
                      onTap: () => onToggleDay(habit.id, i),
                      child: AspectRatio(
                        aspectRatio: 2.2,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: done ? _kHabitGreen : _kDayIncomplete,
                            borderRadius: BorderRadius.circular(8),
                            border: isToday
                                ? Border.all(color: _kHabitGreenDark, width: 2)
                                : null,
                          ),
                          child: done
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dayLabels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _MoodThisWeekCard extends StatelessWidget {
  const _MoodThisWeekCard({
    required this.days,
    required this.average,
    required this.onDayTap,
  });

  final List<MoodDay> days;
  final double average;
  final void Function({required int dayIndex, required String moodTypeId, double? score})
      onDayTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const maxScore = 10.0;

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
                    "Mood This Week",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  "Tap a day to pick mood",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (index) {
                final day = days[index];
                final canTap = index <= WeekCalendar.todayWeekIndex;
                final barHeight = day.score <= 0
                    ? 6.0
                    : 48.0 * (day.score / maxScore).clamp(0.15, 1.0);
                return Expanded(
                  child: GestureDetector(
                    onTap: canTap
                        ? () => _showMoodPicker(context, index, day, onDayTap)
                        : null,
                    child: Opacity(
                      opacity: canTap ? 1 : 0.45,
                      child: Column(
                        children: [
                          Text(day.emoji, style: const TextStyle(fontSize: 22)),
                          if (day.moodTypeLabel != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              day.moodTypeLabel!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: day.score <= 0
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : _kMoodPink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            day.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Center(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  children: [
                    const TextSpan(text: "Average Mood: "),
                    TextSpan(
                      text: average > 0
                          ? "${average.toStringAsFixed(1)}/10"
                          : "—",
                      style: const TextStyle(
                        color: Color(0xFFEC4899),
                        fontWeight: FontWeight.w700,
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

class _TodaysLogCard extends StatelessWidget {
  const _TodaysLogCard({
    required this.logs,
    required this.onAdd,
  });

  final List<TodayLogEntry> logs;
  final VoidCallback onAdd;

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
                Expanded(
                  child: Text(
                    "Today's Log",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kAddBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (logs.isEmpty)
              Text(
                "No entries yet. Tap Add and pick an activity.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...HabitTrackerNotifier.groupLogs(logs).map(
                (group) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LogRow(group: group),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogRow extends StatefulWidget {
  const _LogRow({required this.group});

  final TodayLogGroup group;

  @override
  State<_LogRow> createState() => _LogRowState();
}

class _LogRowState extends State<_LogRow> {
  bool _expanded = false;

  TodayLogGroup get group => widget.group;

  bool get _canExpand =>
      HabitLogDetailsFormatter.hasExpandableHistory(group.sessions);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: theme.brightness == Brightness.dark ? 0.5 : 1,
      ),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: _canExpand ? () => setState(() => _expanded = !_expanded) : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          group.totalSubtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_canExpand)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              if (_expanded && _canExpand) ...[
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 8),
                Text(
                  "Session history",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ...group.sessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 6,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            HabitLogDetailsFormatter.sessionHistoryLine(session),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
