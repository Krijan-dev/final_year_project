import "dart:io";

import "package:flutter/services.dart";
import "package:health/health.dart";
import "package:life_pattern_tracker/services/usage_stats_service.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

/// Result of loading steps/sleep from Health Connect on Android.
class HealthConnectData {
  const HealthConnectData({
    required this.sdkStatus,
    required this.permissionsGranted,
    this.stepsToday,
    this.sleepHoursLastNight,
    this.stepsLast7Days = const [],
    this.errorMessage,
    this.needsInstall = false,
    this.needsPermission = false,
    this.hasData = false,
  });

  final HealthConnectSdkStatus? sdkStatus;
  final bool permissionsGranted;
  final int? stepsToday;
  final double? sleepHoursLastNight;
  final List<HealthDaySteps> stepsLast7Days;
  final String? errorMessage;
  final bool needsInstall;
  final bool needsPermission;
  final bool hasData;

  bool get sdkUsable =>
      sdkStatus == HealthConnectSdkStatus.sdkAvailable ||
      sdkStatus == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
}

class HealthPermissionRequestResult {
  const HealthPermissionRequestResult({
    this.granted = false,
    this.openedSettings = false,
    this.denied = false,
    this.message,
  });

  final bool granted;
  final bool openedSettings;
  final bool denied;
  final String? message;
}

class HealthDaySteps {
  const HealthDaySteps({required this.label, required this.steps});

  final String label;
  final int steps;
}

abstract final class HealthConnectService {
  static const String genericSyncHint =
      "Connect your fitness or watch app to Health Connect, then allow this app "
      "to read Steps and Sleep in the permission screen.";

  static const List<HealthDataType> permissionTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
  ];

  static List<HealthDataAccess> get _permissionAccess =>
      List<HealthDataAccess>.filled(permissionTypes.length, HealthDataAccess.READ);

  static Future<HealthConnectData> load({
    bool includeWeekTrend = true,
    bool requestPermissionIfNeeded = false,
  }) async {
    if (!Platform.isAndroid) {
      return const HealthConnectData(
        sdkStatus: null,
        permissionsGranted: false,
        errorMessage: "Health Connect is only available on Android.",
      );
    }

    try {
      final native = await UsageStatsService().readHealthSummary();
      if (native != null) {
        var data = _fromNativeSummary(native);
        if (data.permissionsGranted && includeWeekTrend) {
          data = await _attachWeekTrend(data);
        }
        if (data.needsPermission && requestPermissionIfNeeded) {
          await requestPermissions();
          final again = await UsageStatsService().readHealthSummary();
          if (again != null) {
            var refreshed = _fromNativeSummary(again);
            if (refreshed.permissionsGranted && includeWeekTrend) {
              refreshed = await _attachWeekTrend(refreshed);
            }
            return refreshed;
          }
        }
        return data;
      }
    } catch (e, st) {
      AppLog.e("HealthConnectService native load failed", error: e, stackTrace: st);
    }

    return _loadViaHealthPlugin(
      includeWeekTrend: includeWeekTrend,
      requestPermissionIfNeeded: requestPermissionIfNeeded,
    );
  }

  static HealthConnectData _fromNativeSummary(Map<dynamic, dynamic> raw) {
    final sdkInt = (raw["sdkStatus"] as num?)?.toInt();
    final sdk = sdkInt != null
        ? HealthConnectSdkStatus.fromNativeValue(sdkInt)
        : HealthConnectSdkStatus.sdkUnavailable;
    final error = raw["error"] as String?;
    final permissionsGranted = raw["permissionsGranted"] == true;
    final stepsToday = (raw["stepsToday"] as num?)?.round() ?? 0;
    final sleepRaw = raw["sleepHours"];
    final sleepHours = sleepRaw is num && sleepRaw > 0 ? sleepRaw.toDouble() : null;

    if (error == "health_connect_not_installed") {
      return HealthConnectData(
        sdkStatus: sdk,
        permissionsGranted: false,
        needsInstall: true,
        errorMessage:
            "Install or update Health Connect from the Play Store, then open it once. "
            "On Android 14+ it may be built into Settings.",
      );
    }

    if (error == "permissions_missing" || !permissionsGranted) {
      return HealthConnectData(
        sdkStatus: sdk,
        permissionsGranted: false,
        needsPermission: true,
        errorMessage:
            "Allow Steps and Sleep for Life Pattern Tracker in Health Connect, then tap Check again.",
      );
    }

    final hasData = stepsToday > 0 || (sleepHours != null && sleepHours > 0);
    return HealthConnectData(
      sdkStatus: sdk,
      permissionsGranted: true,
      stepsToday: stepsToday,
      sleepHoursLastNight: sleepHours,
      hasData: hasData,
      errorMessage: hasData
          ? null
          : "Permissions are on, but no steps or sleep yet. $genericSyncHint Then pull to refresh.",
    );
  }

  static Future<HealthConnectData> _attachWeekTrend(HealthConnectData data) async {
    try {
      final health = Health();
      await health.configure();
      if (await health.getHealthConnectSdkStatus() != HealthConnectSdkStatus.sdkAvailable) {
        return data;
      }
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOf7Days = startOfDay.subtract(const Duration(days: 6));
      final steps7d = <HealthDaySteps>[];
      for (var i = 0; i < 7; i++) {
        final dayStart = startOf7Days.add(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        final s = await health.getTotalStepsInInterval(dayStart, dayEnd);
        steps7d.add(HealthDaySteps(label: _weekdayLabel(dayStart), steps: s ?? 0));
      }
      return HealthConnectData(
        sdkStatus: data.sdkStatus,
        permissionsGranted: data.permissionsGranted,
        stepsToday: data.stepsToday,
        sleepHoursLastNight: data.sleepHoursLastNight,
        stepsLast7Days: steps7d,
        hasData: data.hasData,
        errorMessage: data.errorMessage,
        needsInstall: data.needsInstall,
        needsPermission: data.needsPermission,
      );
    } catch (_) {
      return data;
    }
  }

  static Future<HealthConnectData> _loadViaHealthPlugin({
    required bool includeWeekTrend,
    required bool requestPermissionIfNeeded,
  }) async {
    try {
      final health = Health();
      await health.configure();

      final sdk = await health.getHealthConnectSdkStatus();
      if (!_pluginSdkUsable(sdk)) {
        return HealthConnectData(
          sdkStatus: sdk,
          permissionsGranted: false,
          needsInstall: true,
          errorMessage:
              "Install or update Health Connect from the Play Store, then open it once.",
        );
      }

      var granted = await health.hasPermissions(permissionTypes, permissions: _permissionAccess);
      if (granted != true && requestPermissionIfNeeded) {
        granted = await health.requestAuthorization(permissionTypes, permissions: _permissionAccess);
      }
      if (granted != true) {
        return HealthConnectData(
          sdkStatus: sdk,
          permissionsGranted: false,
          needsPermission: true,
          errorMessage:
              "Allow Steps and Sleep for Life Pattern Tracker in the Health Connect permission screen.",
        );
      }

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final stepsToday = await _readStepsToday(health, startOfDay, now);
      final sleepHours = await _readSleepHours(health, startOfDay, now);

      final steps7d = <HealthDaySteps>[];
      if (includeWeekTrend) {
        final startOf7Days = startOfDay.subtract(const Duration(days: 6));
        for (var i = 0; i < 7; i++) {
          final dayStart = startOf7Days.add(Duration(days: i));
          final dayEnd = dayStart.add(const Duration(days: 1));
          final s = await health.getTotalStepsInInterval(dayStart, dayEnd);
          steps7d.add(HealthDaySteps(label: _weekdayLabel(dayStart), steps: s ?? 0));
        }
      }

      final hasData = stepsToday > 0 || (sleepHours != null && sleepHours > 0);
      return HealthConnectData(
        sdkStatus: sdk,
        permissionsGranted: true,
        stepsToday: stepsToday,
        sleepHoursLastNight: sleepHours,
        stepsLast7Days: steps7d,
        hasData: hasData,
        errorMessage: hasData
            ? null
            : "Permissions are on, but no steps or sleep yet. $genericSyncHint Then pull to refresh.",
      );
    } catch (e, st) {
      AppLog.e("HealthConnectService plugin load failed", error: e, stackTrace: st);
      return HealthConnectData(
        sdkStatus: null,
        permissionsGranted: false,
        errorMessage: _friendlyError(e),
      );
    }
  }

  static bool _pluginSdkUsable(HealthConnectSdkStatus? sdk) =>
      sdk == HealthConnectSdkStatus.sdkAvailable ||
      sdk == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;

  static Future<HealthPermissionRequestResult> requestPermissions() async {
    if (!Platform.isAndroid) {
      return const HealthPermissionRequestResult(denied: true);
    }
    try {
      final health = Health();
      await health.configure();
      final sdk = await health.getHealthConnectSdkStatus();
      if (_pluginSdkUsable(sdk)) {
        var granted = await health.hasPermissions(permissionTypes, permissions: _permissionAccess);
        if (granted != true) {
          granted = await health.requestAuthorization(permissionTypes, permissions: _permissionAccess);
        }
        if (granted == true) {
          return const HealthPermissionRequestResult(granted: true);
        }
      }

      final opened = await UsageStatsService().openHealthConnectPermissions();
      final summary = await UsageStatsService().readHealthSummary();
      final grantedNative = summary?["permissionsGranted"] == true;
      if (grantedNative) {
        return const HealthPermissionRequestResult(granted: true);
      }

      return HealthPermissionRequestResult(
        openedSettings: opened,
        denied: !opened,
        message: opened
            ? "In Health Connect, allow Steps and Sleep for this app, then tap Check again."
            : "Could not open Health Connect. Install it from the Play Store first.",
      );
    } catch (e, st) {
      AppLog.e("HealthConnectService.requestPermissions failed", error: e, stackTrace: st);
      final opened = await UsageStatsService().openHealthConnectPermissions();
      return HealthPermissionRequestResult(
        openedSettings: opened,
        denied: !opened,
        message: _friendlyError(e),
      );
    }
  }

  static Future<void> installOrUpdateHealthConnect() async {
    if (!Platform.isAndroid) return;
    try {
      final opened = await UsageStatsService().openHealthConnectApp();
      if (opened) return;
      final health = Health();
      await health.configure();
      await health.installHealthConnect();
    } catch (e, st) {
      AppLog.e("HealthConnectService.install failed", error: e, stackTrace: st);
    }
  }

  static Future<int> _readStepsToday(Health health, DateTime start, DateTime end) async {
    final total = await health.getTotalStepsInInterval(start, end);
    if (total != null && total > 0) return total;

    final points = await health.getHealthDataFromTypes(
      types: const [HealthDataType.STEPS],
      startTime: start,
      endTime: end,
    );
    var sum = 0;
    for (final p in points) {
      final v = p.value;
      if (v is NumericHealthValue) {
        sum += v.numericValue.round();
      }
    }
    return sum;
  }

  static Future<double?> _readSleepHours(
    Health health,
    DateTime startOfDay,
    DateTime now,
  ) async {
    final sleepEnd = now;
    final sleepStart = startOfDay.subtract(const Duration(hours: 24));

    for (final types in const [
      [HealthDataType.SLEEP_SESSION],
      [HealthDataType.SLEEP_ASLEEP],
    ]) {
      final points = await health.getHealthDataFromTypes(
        types: types,
        startTime: sleepStart,
        endTime: sleepEnd,
      );
      if (points.isEmpty) continue;
      var hours = 0.0;
      for (final p in points) {
        hours += p.dateTo.difference(p.dateFrom).inMinutes / 60.0;
      }
      if (hours > 0) return hours;
    }
    return null;
  }

  static String _weekdayLabel(DateTime d) {
    const labels = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return labels[(d.weekday - 1).clamp(0, 6)];
  }

  static String _friendlyError(Object e) {
    if (e is MissingPluginException) {
      return "Health Connect needs a full app rebuild. Reinstall the latest tester APK.";
    }
    return "Could not read Health Connect. Open Health Connect, confirm Steps & Sleep are allowed for this app, then tap Check again.";
  }
}
