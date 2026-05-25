import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_storage_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/services/habit_remote_service.dart";
import "package:life_pattern_tracker/services/habit_tracker_storage_service.dart";
import "package:life_pattern_tracker/services/usage_remote_service.dart";
import "package:life_pattern_tracker/services/usage_storage_service.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

/// Pushes local Hive data to MongoDB after sign-in or on demand.
abstract final class CloudSyncService {
  static bool get isConfigured => AuthRemoteService.isConfigured;

  static Future<void> pushAll() async {
    if (!isConfigured) return;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return;
    final email = await AuthStorageService().getSessionEmail();
    if (email == null || email.isEmpty) return;

    try {
      await _pushUsage(email);
      await _pushHabits(email);
    } catch (e, st) {
      AppLog.e("CloudSyncService.pushAll failed", error: e, stackTrace: st);
    }
  }

  static Future<void> _pushUsage(String email) async {
    final days = await UsageStorageService().getAllDays();
    final remote = UsageRemoteService();
    for (final day in days) {
      await remote.uploadUsageDay(userEmail: email, day: day);
    }
  }

  static Future<void> _pushHabits(String email) async {
    final raw = await HabitTrackerStorageService().loadRaw();
    if (raw == null) return;
    final weekKey = raw["weekKey"] as String? ?? "";
    if (weekKey.isEmpty) return;
    await HabitRemoteService().uploadSnapshot(
      userEmail: email,
      weekKey: weekKey,
      payload: {
        "weekKey": weekKey,
        "habits": raw["habits"] ?? [],
        "moodDays": raw["moodDays"] ?? [],
        "logs": raw["logs"] ?? [],
      },
    );
  }
}
