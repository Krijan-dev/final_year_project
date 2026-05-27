import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";

/// Local notifications when a per-app daily screen time limit is exceeded.
class ScreenTimeNotificationService {
  ScreenTimeNotificationService._();
  static final ScreenTimeNotificationService instance = ScreenTimeNotificationService._();

  static const _channelId = "screen_time_limits";
  static const _channelName = "Screen time limits";
  static const _channelDescription = "Alerts when an app exceeds your daily limit";

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (!Platform.isAndroid || _initialized) return;

    const androidInit = AndroidInitializationSettings("@mipmap/ic_launcher");
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(settings: initSettings);

    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(androidChannel);

    _initialized = true;
  }

  /// Android 13+ — returns true if allowed or not applicable.
  Future<bool> ensureAndroidPostPermission() async {
    if (!Platform.isAndroid) return true;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<bool> hasAndroidPostPermission() async {
    if (!Platform.isAndroid) return true;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final enabled = await android.areNotificationsEnabled();
    return enabled ?? true;
  }

  /// Stable id per package for today's notification (replaces same notification).
  static int notificationIdFor(String packageName) {
    var h = packageName.hashCode & 0x7fffffff;
    if (h < 1000) h += 1000;
    return h;
  }

  Future<void> showLimitExceeded({
    required String packageName,
    required String appLabel,
    required int usedMinutes,
    required int limitMinutes,
  }) async {
    if (!Platform.isAndroid) return;
    await init();
    if (!await hasAndroidPostPermission()) return;

    // Gentle tone per requirement: not alarming, suggests a break.
    final title = "Screen time limit reached";
    final body =
        "$appLabel looks like you've hit your $limitMinutes-minute daily limit ($usedMinutes minutes). "
        "Want a quick break?";

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      ),
    );

    try {
      await _plugin.show(
        id: notificationIdFor(packageName),
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (e, st) {
      debugPrint("ScreenTimeNotificationService.show failed: $e\n$st");
    }
  }
}
