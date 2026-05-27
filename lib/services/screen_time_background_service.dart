import "dart:io";

import "package:flutter/services.dart";
import "package:life_pattern_tracker/models/app_screen_time_limit.dart";

/// Syncs limits to native Android so a periodic background worker can check usage.
class ScreenTimeBackgroundService {
  static const MethodChannel _channel = MethodChannel("life_pattern_tracker/usage");

  Future<void> syncLimits(Map<String, AppScreenTimeLimit> limitsByPackage) async {
    if (!Platform.isAndroid) return;
    final limits = limitsByPackage.values
        .map((l) => {
              "packageName": l.packageName,
              "displayName": l.displayName,
              "limitMinutesPerDay": l.limitMinutesPerDay,
              "notifyWhenExceeded": l.notifyWhenExceeded,
            })
        .toList(growable: false);
    try {
      await _channel.invokeMethod<void>(
        "updateScreenTimeLimits",
        {"limits": limits},
      );
    } on MissingPluginException {
      // Native side not available in current build yet.
    } on PlatformException {
      // Ignore soft failures; foreground checks still work.
    }
  }
}

