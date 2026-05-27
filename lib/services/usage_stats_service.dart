import "dart:io";

import "package:flutter/services.dart";
import "package:life_pattern_tracker/models/app_usage_model.dart";
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/models/installed_app_model.dart";
import "package:life_pattern_tracker/utils/dev_spoof.dart";

class UsageStatsService {
  static const MethodChannel _channel = MethodChannel("life_pattern_tracker/usage");

  Future<bool> hasUsagePermission() async {
    if (DevSpoof.enabled) return true;
    if (!Platform.isAndroid) return false;
    final result = await _channel
        .invokeMethod<bool>("hasUsagePermission")
        .timeout(const Duration(seconds: 10), onTimeout: () => false);
    return result ?? false;
  }

  Future<void> openUsageAccessSettings() async {
    if (DevSpoof.enabled) return;
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>("openUsageAccessSettings");
  }

  Future<DailyUsageModel?> getUsageStats({DateTime? day}) async {
    if (DevSpoof.enabled) {
      return _spoofUsage(day ?? DateTime.now());
    }
    if (!Platform.isAndroid) return null;
    final payload = await _channel
        .invokeMethod<Map<dynamic, dynamic>>(
      "getUsageStats",
      {
        "startMillis": _startOfDay(day ?? DateTime.now()).millisecondsSinceEpoch,
        "endMillis": _endOfDay(day ?? DateTime.now()).millisecondsSinceEpoch,
      },
    )
        .timeout(
      const Duration(seconds: 45),
      onTimeout: () => null,
    );
    if (payload == null) return null;
    return DailyUsageModel.fromMap(
      Map<String, dynamic>.from(payload),
    );
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  Future<List<InstalledAppModel>> listInstalledApps() async {
    if (!Platform.isAndroid) return const [];
    try {
      final payload = await _channel
          .invokeMethod<List<dynamic>>("listInstalledApps")
          .timeout(const Duration(seconds: 20), onTimeout: () => const []);
      if (payload == null) return const [];
      return payload
          .whereType<Map>()
          .map((e) => InstalledAppModel.fromMap(Map<String, dynamic>.from(e)))
          .where((e) => e.packageName.isNotEmpty)
          .toList();
    } on MissingPluginException {
      throw StateError(
        "Installed apps API is not available in the current build. "
        "Please fully stop and run the app again.",
      );
    } on PlatformException catch (e) {
      throw StateError("Could not load installed apps: ${e.message ?? e.code}");
    }
  }

  Future<Uint8List?> getAppIcon(String packageName) async {
    if (!Platform.isAndroid || packageName.isEmpty) return null;
    try {
      final payload = await _channel.invokeMethod<Uint8List>(
        "getAppIcon",
        {"packageName": packageName},
      );
      return payload;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  DailyUsageModel _spoofUsage(DateTime day) {
    final now = DateTime.now();
    final level = DevSpoof.level;

    // Match your requested three qualities (Best / Medium / Bad).
    late final List<int> hourly;
    late final List<AppUsageModel> apps;

    switch (level) {
      case DevSpoofLevel.best:
        // ~420 minutes with a healthy mix.
        hourly = const <int>[
          0, 0, 5, 15, 25, 35,
          40, 55, 45, 35, 30, 25,
          20, 15, 10, 15, 20, 30,
          0, 0, 0, 0, 0, 0,
        ];
        apps = [
          AppUsageModel(
            appName: "TikTok",
            packageName: "com.zhiliaoapp.musically",
            usageTime: 90,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "Instagram",
            packageName: "com.instagram.android",
            usageTime: 70,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "YouTube",
            packageName: "com.google.android.youtube",
            usageTime: 30,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "Slack",
            packageName: "com.Slack",
            usageTime: 60,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "productivity",
          ),
          AppUsageModel(
            appName: "Notion",
            packageName: "org.notion.electron",
            usageTime: 50,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "productivity",
          ),
          AppUsageModel(
            appName: "Google Docs",
            packageName: "com.google.android.apps.docs",
            usageTime: 40,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "education",
          ),
          AppUsageModel(
            appName: "Clash of Clans",
            packageName: "com.supercell.clashofclans",
            usageTime: 50,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "game",
          ),
          AppUsageModel(
            appName: "Spotify",
            packageName: "com.spotify.music",
            usageTime: 30,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "audio",
          ),
        ];
        break;
      case DevSpoofLevel.medium:
        // ~260 minutes: still some social, but more productive.
        hourly = const <int>[
          0, 0, 2, 8, 15, 18,
          22, 28, 30, 26, 20, 18,
          14, 12, 10, 12, 14, 16,
          0, 0, 0, 0, 0, 0,
        ];
        apps = [
          AppUsageModel(
            appName: "TikTok",
            packageName: "com.zhiliaoapp.musically",
            usageTime: 45,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "Instagram",
            packageName: "com.instagram.android",
            usageTime: 35,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "YouTube",
            packageName: "com.google.android.youtube",
            usageTime: 20,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "Slack",
            packageName: "com.Slack",
            usageTime: 35,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "productivity",
          ),
          AppUsageModel(
            appName: "Notion",
            packageName: "org.notion.electron",
            usageTime: 40,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "productivity",
          ),
          AppUsageModel(
            appName: "Google Docs",
            packageName: "com.google.android.apps.docs",
            usageTime: 25,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "education",
          ),
          AppUsageModel(
            appName: "Clash of Clans",
            packageName: "com.supercell.clashofclans",
            usageTime: 18,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "game",
          ),
          AppUsageModel(
            appName: "Spotify",
            packageName: "com.spotify.music",
            usageTime: 12,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "audio",
          ),
        ];
        break;
      case DevSpoofLevel.bad:
        // ~650 minutes: heavy social + games.
        hourly = const <int>[
          5, 10, 25, 35, 50, 60,
          70, 75, 60, 55, 45, 40,
          30, 25, 20, 25, 30, 35,
          15, 10, 5, 0, 0, 0,
        ];
        apps = [
          AppUsageModel(
            appName: "TikTok",
            packageName: "com.zhiliaoapp.musically",
            usageTime: 170,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "Instagram",
            packageName: "com.instagram.android",
            usageTime: 140,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "YouTube",
            packageName: "com.google.android.youtube",
            usageTime: 95,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "X / Twitter",
            packageName: "com.twitter.android",
            usageTime: 60,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "Reddit",
            packageName: "com.andrewshu.android.reddit",
            usageTime: 40,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "social",
          ),
          AppUsageModel(
            appName: "Slack",
            packageName: "com.Slack",
            usageTime: 20,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "productivity",
          ),
          AppUsageModel(
            appName: "Clash of Clans",
            packageName: "com.supercell.clashofclans",
            usageTime: 55,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "game",
          ),
          AppUsageModel(
            appName: "Spotify",
            packageName: "com.spotify.music",
            usageTime: 25,
            lastUsedEpochMillis: now.millisecondsSinceEpoch,
            category: "audio",
          ),
        ];
        break;
      case DevSpoofLevel.off:
        // Should not be hit because _spoofUsage is only called when enabled.
        hourly = const <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        apps = const [];
    }

    final total = hourly.reduce((a, b) => a + b);
    return DailyUsageModel(
      date: DateTime(day.year, day.month, day.day),
      totalScreenTime: total,
      appUsages: apps,
      hourlyUsageMinutes: hourly,
    );
  }
}
