import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_storage_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/services/habit_remote_service.dart";
import "package:life_pattern_tracker/services/habit_tracker_storage_service.dart";
import "package:life_pattern_tracker/services/usage_remote_service.dart";
import "package:life_pattern_tracker/services/usage_storage_service.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

/// Syncs local Hive data with MongoDB (pull on sign-in, push after changes).
abstract final class CloudSyncService {
  static bool get isConfigured => AuthRemoteService.isConfigured;

  /// Full restore (usage + habits). Use from Account -> Refresh all data.
  static Future<bool> restoreFromCloud({bool includeUsage = true}) async {
    if (!isConfigured) return false;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return false;
    final email = await AuthStorageService().getSessionEmail();
    if (email == null || email.isEmpty) return false;

    var restored = false;
    try {
      if (includeUsage) {
        restored = await _pullUsage(email) || restored;
      }
      restored = await _pullHabitsIfLocalEmpty(email) || restored;
    } catch (e, st) {
      AppLog.e("CloudSyncService.restoreFromCloud failed", error: e, stackTrace: st);
    }
    return restored;
  }

  /// After login: habits from cloud only if this install has none; never overwrite
  /// screen time from cloud (phone Usage Access is the source of truth).
  static Future<void> syncOnSignIn() async {
    if (!isConfigured) return;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return;
    final email = await AuthStorageService().getSessionEmail();
    if (email == null || email.isEmpty) return;

    try {
      await _pullHabitsIfLocalEmpty(email);
      await pushAll();
    } catch (e, st) {
      AppLog.e("CloudSyncService.syncOnSignIn failed", error: e, stackTrace: st);
    }
  }

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

  static Future<bool> _pullUsage(String email) async {
    final remote = UsageRemoteService();
    final days = await remote.fetchAllUsageDays(userEmail: email);
    if (days.isEmpty) return false;
    final storage = UsageStorageService();
    for (final day in days) {
      await storage.saveDay(day);
    }
    return true;
  }

  /// Only download habits when this device has no local habit data yet.
  static Future<bool> _pullHabitsIfLocalEmpty(String email) async {
    final local = await HabitTrackerStorageService().loadRaw();
    if (local != null) return false;

    final snap = await HabitRemoteService().fetchLatestSnapshot(userEmail: email);
    if (snap == null || snap.isEmpty) return false;
    final weekKey = snap["weekKey"] as String? ?? "";
    if (weekKey.isEmpty) return false;
    await HabitTrackerStorageService().save(
      weekKey: weekKey,
      habits: HabitTrackerStorageService.parseHabits(snap["habits"] as List?),
      moodDays: HabitTrackerStorageService.parseMoodDays(snap["moodDays"] as List?),
      logs: HabitTrackerStorageService.parseLogs(snap["logs"] as List?),
    );
    return true;
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
