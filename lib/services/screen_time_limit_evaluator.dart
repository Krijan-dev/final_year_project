import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/services/app_screen_time_limit_storage.dart";
import "package:life_pattern_tracker/services/screen_time_notification_service.dart";
import "package:life_pattern_tracker/utils/dev_spoof.dart";

/// Compares today's usage against saved limits and fires at most one notification per app per day.
class ScreenTimeLimitEvaluator {
  ScreenTimeLimitEvaluator({
    AppScreenTimeLimitStorage? storage,
    ScreenTimeNotificationService? notifications,
  })  : _storage = storage ?? AppScreenTimeLimitStorage(),
        _notifications = notifications ?? ScreenTimeNotificationService.instance;

  final AppScreenTimeLimitStorage _storage;
  final ScreenTimeNotificationService _notifications;

  Future<void> evaluate(DailyUsageModel? today) async {
    if (today == null) return;
    if (DevSpoof.enabled) {
      // Optional: still evaluate so spoof demos notifications; user may want real notifs off.
    }

    final limits = await _storage.loadAll();
    if (limits.isEmpty) return;

    final day = DateTime(today.date.year, today.date.month, today.date.day);
    final usageByPkg = {for (final a in today.appUsages) a.packageName: a};

    for (final limit in limits.values) {
      if (!limit.notifyWhenExceeded) continue;
      if (limit.limitMinutesPerDay <= 0) continue;

      final app = usageByPkg[limit.packageName];
      final used = app?.usageTime ?? 0;
      if (used < limit.limitMinutesPerDay) continue;

      if (await _storage.wasNotifiedToday(limit.packageName, day)) continue;

      final label = app?.appName ?? limit.displayName;
      if (label.isEmpty) continue;

      await _notifications.showLimitExceeded(
        packageName: limit.packageName,
        appLabel: label,
        usedMinutes: used,
        limitMinutes: limit.limitMinutesPerDay,
      );
      await _storage.markNotifiedToday(limit.packageName, day);
    }
  }
}
