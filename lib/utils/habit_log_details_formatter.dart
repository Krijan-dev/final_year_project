import "package:life_pattern_tracker/data/habit_log_presets.dart";
import "package:life_pattern_tracker/models/habit_log_preset.dart";
import "package:life_pattern_tracker/models/today_log_entry.dart";

/// How optional amount/details are stored for a log entry.
enum HabitLogAmountUnit {
  minutes,
  glasses,
  hours,
  freeText,
}

abstract final class HabitLogDetailsFormatter {
  static HabitLogAmountUnit unitForPreset(HabitLogPreset preset) => preset.amountUnit;

  static HabitLogAmountUnit unitForCustomTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.contains("water") || t.contains("drink") || t.contains("hydrat")) {
      return HabitLogAmountUnit.glasses;
    }
    if (t.contains("sleep") || t.contains("nap")) {
      return HabitLogAmountUnit.hours;
    }
    if (t.contains("mood") || t.contains("meal") || t.contains("eat") || t.contains("journal")) {
      return HabitLogAmountUnit.freeText;
    }
    if (_looksDurationBased(t)) {
      return HabitLogAmountUnit.minutes;
    }
    return HabitLogAmountUnit.freeText;
  }

  static bool _looksDurationBased(String t) {
    const keys = [
      "workout",
      "exercise",
      "walk",
      "run",
      "meditat",
      "read",
      "study",
      "stretch",
      "screen",
      "break",
    ];
    for (final k in keys) {
      if (t.contains(k)) return true;
    }
    return false;
  }

  /// Normalizes user input; strips wrong units and applies the correct one.
  static String format(String raw, HabitLogAmountUnit unit) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return "";

    switch (unit) {
      case HabitLogAmountUnit.minutes:
        return _formatMinutes(trimmed);
      case HabitLogAmountUnit.glasses:
        return _formatGlasses(trimmed);
      case HabitLogAmountUnit.hours:
        return _formatHours(trimmed);
      case HabitLogAmountUnit.freeText:
        return trimmed;
    }
  }

  /// Value to show in the amount field when editing an existing log.
  static String editValue(String storedSubtitle, HabitLogAmountUnit unit) {
    if (storedSubtitle.isEmpty || storedSubtitle == "Logged") return "";

    switch (unit) {
      case HabitLogAmountUnit.minutes:
        return _stripSuffix(
          storedSubtitle,
          RegExp(r"\s*min(?:ute)?s?\s*$", caseSensitive: false),
        );
      case HabitLogAmountUnit.glasses:
        return _stripSuffix(
          storedSubtitle,
          RegExp(r"\s*glass(?:es)?\s*$", caseSensitive: false),
        );
      case HabitLogAmountUnit.hours:
        return _stripSuffix(
          storedSubtitle,
          RegExp(r"\s*h(?:ou)?rs?\s*$", caseSensitive: false),
        );
      case HabitLogAmountUnit.freeText:
        return storedSubtitle;
    }
  }

  static String amountLabel(HabitLogAmountUnit unit) {
    switch (unit) {
      case HabitLogAmountUnit.minutes:
        return "Amount (minutes)";
      case HabitLogAmountUnit.glasses:
        return "Amount (glasses)";
      case HabitLogAmountUnit.hours:
        return "Amount (hours)";
      case HabitLogAmountUnit.freeText:
        return "Notes (optional)";
    }
  }

  static String amountHint(HabitLogAmountUnit unit) {
    switch (unit) {
      case HabitLogAmountUnit.minutes:
        return "e.g. 20";
      case HabitLogAmountUnit.glasses:
        return "e.g. 2";
      case HabitLogAmountUnit.hours:
        return "e.g. 8";
      case HabitLogAmountUnit.freeText:
        return "e.g. Feeling good";
    }
  }

  static String _formatMinutes(String raw) {
    final n = _parseNumber(raw);
    if (n != null) return n == 1 ? "1 min" : "$n min";
    return _stripWrongUnits(raw, HabitLogAmountUnit.minutes);
  }

  static String _formatGlasses(String raw) {
    final n = _parseNumber(raw);
    if (n != null) return n == 1 ? "1 glass" : "$n glasses";
    return _stripWrongUnits(raw, HabitLogAmountUnit.glasses);
  }

  static String _formatHours(String raw) {
    final n = _parseDecimal(raw);
    if (n != null) {
      final label = n == 1 ? "hour" : "hours";
      final text = n == n.roundToDouble() ? n.toInt().toString() : n.toString();
      return "$text $label";
    }
    return _stripWrongUnits(raw, HabitLogAmountUnit.hours);
  }

  /// Removes common unit words so a wrong unit can be re-applied correctly.
  static String _stripWrongUnits(String raw, HabitLogAmountUnit target) {
    var s = raw.trim();
    s = s.replaceAll(
      RegExp(
        r"\s*(min(?:ute)?s?|mins?|m|glass(?:es)?|cup(?:s)?|h(?:ou)?rs?|hrs?)\s*",
        caseSensitive: false,
      ),
      " ",
    );
    s = s.trim();
    if (s.isEmpty) return raw.trim();
    return format(s, target);
  }

  static int? _parseNumber(String raw) {
    final n = _parseDecimal(raw);
    if (n == null) return null;
    if (n != n.roundToDouble()) return null;
    return n.toInt();
  }

  static double? _parseDecimal(String raw) {
    final match = RegExp(r"(\d+(?:\.\d+)?)").firstMatch(raw.trim());
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }

  static String _stripSuffix(String value, RegExp suffix) {
    return value.replaceAll(suffix, "").trim();
  }

  static HabitLogAmountUnit unitForActivityKey(String activityKey, String title) {
    final preset = HabitLogPresets.byId(activityKey);
    if (preset != null) return preset.amountUnit;
    return unitForCustomTitle(title);
  }

  static bool isTimeOptional(String activityKey, String title) {
    final preset = HabitLogPresets.byId(activityKey);
    if (preset != null) return preset.timeOptional;
    final t = title.trim().toLowerCase();
    return t.contains("water") ||
        t.contains("drink") ||
        t.contains("hydrat");
  }

  static bool hasExpandableHistory(List<TodayLogEntry> sessions) {
    if (sessions.length > 1) return true;
    return sessions.any((s) => s.timeLabel.trim().isNotEmpty);
  }

  /// One line in the expanded session history list.
  static String sessionHistoryLine(TodayLogEntry session) {
    final time = session.timeLabel.trim();
    final amount =
        session.subtitle.trim().isEmpty || session.subtitle == "Logged"
            ? ""
            : session.subtitle.trim();
    if (time.isEmpty && amount.isEmpty) return "Logged";
    if (time.isEmpty) return amount;
    if (amount.isEmpty) return time;
    return "$time · $amount";
  }

  static int minutesFromSubtitle(String subtitle) {
    if (subtitle.isEmpty || subtitle == "Logged") return 0;
    return _parseNumber(subtitle) ?? 0;
  }

  static int glassesFromSubtitle(String subtitle) {
    if (subtitle.isEmpty || subtitle == "Logged") return 0;
    return _parseNumber(subtitle) ?? 0;
  }

  static double hoursFromSubtitle(String subtitle) {
    if (subtitle.isEmpty || subtitle == "Logged") return 0;
    return _parseDecimal(subtitle) ?? 0;
  }

  /// Combined amount across sessions for display in Today's Log.
  static String summarizeTotal(
    List<TodayLogEntry> sessions,
    HabitLogAmountUnit unit,
  ) {
    if (sessions.isEmpty) return "Logged";

    switch (unit) {
      case HabitLogAmountUnit.minutes:
        final total = sessions.fold<int>(
          0,
          (sum, e) => sum + minutesFromSubtitle(e.subtitle),
        );
        if (total == 0) return _freeTextSummary(sessions);
        final count = sessions.length;
        final amount = total == 1 ? "1 min" : "$total min";
        if (count <= 1) return amount;
        return "$amount total · $count sessions";
      case HabitLogAmountUnit.glasses:
        final total = sessions.fold<int>(
          0,
          (sum, e) => sum + glassesFromSubtitle(e.subtitle),
        );
        if (total == 0) return _freeTextSummary(sessions);
        final amount = total == 1 ? "1 glass" : "$total glasses";
        if (sessions.length <= 1) return amount;
        return "$amount total · ${sessions.length} sessions";
      case HabitLogAmountUnit.hours:
        final total = sessions.fold<double>(
          0,
          (sum, e) => sum + hoursFromSubtitle(e.subtitle),
        );
        if (total == 0) return _freeTextSummary(sessions);
        final label = total == 1 ? "hour" : "hours";
        final text =
            total == total.roundToDouble() ? total.toInt().toString() : total.toString();
        final amount = "$text $label";
        if (sessions.length <= 1) return amount;
        return "$amount total · ${sessions.length} sessions";
      case HabitLogAmountUnit.freeText:
        return _freeTextSummary(sessions);
    }
  }

  static String summarizeTimes(List<TodayLogEntry> sessions) {
    final times =
        sessions.map((e) => e.timeLabel.trim()).where((t) => t.isNotEmpty);
    return times.join(" · ");
  }

  static String _freeTextSummary(List<TodayLogEntry> sessions) {
    final notes = sessions
        .map((e) => e.subtitle)
        .where((s) => s.isNotEmpty && s != "Logged")
        .toList();
    if (notes.isEmpty) {
      return sessions.length <= 1 ? "Logged" : "${sessions.length} sessions";
    }
    if (sessions.length <= 1) return notes.first;
    return notes.join(" · ");
  }
}
