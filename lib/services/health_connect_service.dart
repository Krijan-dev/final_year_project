import "dart:io";

import "package:flutter/services.dart";
import "package:health/health.dart";
import "package:intl/intl.dart";
import "package:life_pattern_tracker/services/manual_sleep_storage.dart";
import "package:life_pattern_tracker/services/usage_stats_service.dart";
import "package:life_pattern_tracker/utils/app_log.dart";
import "package:life_pattern_tracker/utils/today_date.dart";

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
    this.installedFitnessAppNames = const [],
    this.dataSourceLabels = const [],
    this.lastDataUpdateMillis,
    this.lastDataSourceLabel,
    this.dataMayBeStale = false,
    this.stepsPermissionGranted = false,
    this.sleepPermissionGranted = false,
    this.partialPermissionHint,
    this.sleepIsManual = false,
    this.stepsDataSourceLine,
    this.sleepDataSourceLine,
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
  /// Fitness / watch apps detected on the device (Samsung Health, Fitbit, etc.).
  final List<String> installedFitnessAppNames;
  /// Apps that actually supplied today's steps or sleep in Health Connect.
  final List<String> dataSourceLabels;
  /// Epoch ms of the newest step/sleep record in Health Connect (fitness sources preferred).
  final int? lastDataUpdateMillis;
  final String? lastDataSourceLabel;
  /// True when the newest record is older than ~6 hours (after 10 AM local).
  final bool dataMayBeStale;
  final bool stepsPermissionGranted;
  final bool sleepPermissionGranted;
  final String? partialPermissionHint;
  /// True when last-night sleep came from manual entry (Health Connect had none).
  final bool sleepIsManual;
  /// e.g. "Steps from Health Connect · phone records · Samsung Health"
  final String? stepsDataSourceLine;
  /// e.g. "Sleep from Health Connect · phone records · Samsung Health"
  final String? sleepDataSourceLine;

  int get sleepScorePercent => SleepScore.percent(sleepHoursLastNight);

  DateTime? get lastDataUpdate => lastDataUpdateMillis == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastDataUpdateMillis!);

  bool get sdkUsable =>
      sdkStatus == HealthConnectSdkStatus.sdkAvailable ||
      sdkStatus == HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;

  String get syncHint => HealthConnectService.syncHintFor(
        installedFitnessAppNames: installedFitnessAppNames,
        dataSourceLabels: dataSourceLabels,
      );

  /// Human-readable sync / freshness line for the Health UI.
  String? get freshnessSubtitle {
    if (!permissionsGranted) return null;

    final source = lastDataSourceLabel ??
        (dataSourceLabels.isNotEmpty ? dataSourceLabels.first : null);

    if (dataMayBeStale) {
      if (lastDataUpdate == null) {
        if (installedFitnessAppNames.isNotEmpty) {
          return "No recent data from ${installedFitnessAppNames.first} in Health Connect. "
              "Open it, enable Health Connect sharing, then tap Refresh.";
        }
        return "No recent steps or sleep in Health Connect. Open your fitness app, then tap Refresh.";
      }
      final time = DateFormat.jm().format(lastDataUpdate!);
      final from = source ?? "your fitness app";
      return "Last update $time from $from — data may be stale. Open the fitness app to sync, then Refresh.";
    }

    if (lastDataUpdate != null) {
      final time = DateFormat.jm().format(lastDataUpdate!);
      final from = source ?? "Health Connect";
      return "Last updated $time from $from";
    }

    return null;
  }
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

  static String syncHintFor({
    List<String> installedFitnessAppNames = const [],
    List<String> dataSourceLabels = const [],
  }) {
    if (dataSourceLabels.isNotEmpty) {
      return "Steps and sleep from ${dataSourceLabels.join(', ')} via Health Connect.";
    }
    if (installedFitnessAppNames.isNotEmpty) {
      final shown = installedFitnessAppNames.take(3).join(', ');
      final extra = installedFitnessAppNames.length > 3
          ? " (+${installedFitnessAppNames.length - 3} more)"
          : "";
      return "Found $shown$extra on your phone. Open it, turn on Health Connect sharing, then tap Check again.";
    }
    return genericSyncHint;
  }

  static Future<bool> openPrimaryFitnessApp() =>
      UsageStatsService().openPrimaryFitnessApp();

  /// Request only types that map to HC permissions (Steps + Sleep session).
  static const List<HealthDataType> permissionTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_SESSION,
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
        if (data.permissionsGranted) {
          data = await _enrichFromPlugin(data);
        }
        if (data.permissionsGranted && includeWeekTrend) {
          data = await _attachWeekTrend(data);
        }
        if (data.needsPermission && requestPermissionIfNeeded) {
          await requestPermissions();
          final again = await UsageStatsService().readHealthSummary();
          if (again != null) {
            var refreshed = _fromNativeSummary(again);
            if (refreshed.permissionsGranted) {
              refreshed = await _enrichFromPlugin(refreshed);
              if (includeWeekTrend) {
                refreshed = await _attachWeekTrend(refreshed);
              }
              refreshed = await _applyManualSleepFallback(refreshed);
            }
            return refreshed;
          }
        }
        if (data.permissionsGranted) {
          data = await _applyManualSleepFallback(data);
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

  static List<String> _parseInstalledFitnessNames(Map<dynamic, dynamic> raw) {
    final list = raw["installedFitnessApps"];
    if (list is! List) return const [];
    final names = <String>[];
    for (final item in list) {
      if (item is Map) {
        final name = item["displayName"]?.toString().trim();
        if (name != null && name.isNotEmpty) names.add(name);
      }
    }
    return names;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static HealthConnectData _fromNativeSummary(Map<dynamic, dynamic> raw) {
    final sdkInt = (raw["sdkStatus"] as num?)?.toInt();
    final sdk = sdkInt != null
        ? HealthConnectSdkStatus.fromNativeValue(sdkInt)
        : HealthConnectSdkStatus.sdkUnavailable;
    final error = raw["error"] as String?;
    final permissionsGranted = raw["permissionsGranted"] == true;
    final stepsPerm = raw["stepsPermissionGranted"] == true;
    final sleepPerm = raw["sleepPermissionGranted"] == true;
    final partialHint = raw["partialPermissionHint"] as String?;
    final stepsToday = (raw["stepsToday"] as num?)?.round() ?? 0;
    final sleepRaw = raw["sleepHours"];
    final sleepHours = sleepRaw is num && sleepRaw > 0 ? sleepRaw.toDouble() : null;
    final installed = _parseInstalledFitnessNames(raw);
    final sources = _parseStringList(raw["dataSourceLabels"]);
    final lastMs = (raw["lastDataUpdateMillis"] as num?)?.toInt();
    final lastSource = raw["lastDataSourceLabel"] as String?;
    final stale = raw["dataMayBeStale"] == true;
    final stepsSourceLine = raw["stepsDataSourceLine"] as String?;
    final sleepSourceLine = raw["sleepDataSourceLine"] as String?;
    final hint = syncHintFor(
      installedFitnessAppNames: installed,
      dataSourceLabels: sources,
    );

    if (error == "health_connect_not_installed") {
      return HealthConnectData(
        sdkStatus: sdk,
        permissionsGranted: false,
        needsInstall: true,
        installedFitnessAppNames: installed,
        dataSourceLabels: sources,
        lastDataUpdateMillis: lastMs,
        lastDataSourceLabel: lastSource,
        dataMayBeStale: stale,
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
        installedFitnessAppNames: installed,
        dataSourceLabels: sources,
        lastDataUpdateMillis: lastMs,
        lastDataSourceLabel: lastSource,
        dataMayBeStale: stale,
        errorMessage:
            "Allow Steps and Sleep for Life Pattern Tracker in Health Connect, then tap Check again.",
      );
    }

    final hasData = stepsToday > 0 || (sleepHours != null && sleepHours > 0);
    String? message;
    if (!hasData) {
      message = "Permissions are on, but no steps or sleep yet. $hint Then pull to refresh.";
    } else if (partialHint != null && partialHint.isNotEmpty) {
      message = partialHint;
    } else if (!sleepPerm && stepsToday > 0) {
      message =
          "Steps are showing. In Health Connect, also allow Sleep for this app, then refresh.";
    }

    return HealthConnectData(
      sdkStatus: sdk,
      permissionsGranted: true,
      stepsToday: stepsToday,
      sleepHoursLastNight: sleepHours,
      hasData: hasData,
      installedFitnessAppNames: installed,
      dataSourceLabels: sources,
      lastDataUpdateMillis: lastMs,
      lastDataSourceLabel: lastSource,
      dataMayBeStale: stale,
      stepsPermissionGranted: stepsPerm,
      sleepPermissionGranted: sleepPerm,
      partialPermissionHint: partialHint,
      stepsDataSourceLine: stepsSourceLine,
      sleepDataSourceLine: sleepSourceLine,
      errorMessage: message,
    );
  }

  static Future<HealthConnectData> _applyManualSleepFallback(HealthConnectData data) async {
    final manual = await ManualSleepStorage.hoursForViewDay(TodayDate.dayKey);
    final hc = data.sleepHoursLastNight;
    if (manual == null) return data;
    if (hc != null && hc > 0) return data;

    final hasData = (data.stepsToday ?? 0) > 0 || manual > 0;
    return HealthConnectData(
      sdkStatus: data.sdkStatus,
      permissionsGranted: data.permissionsGranted,
      stepsToday: data.stepsToday,
      sleepHoursLastNight: manual,
      stepsLast7Days: data.stepsLast7Days,
      hasData: hasData,
      errorMessage: data.errorMessage,
      needsInstall: data.needsInstall,
      needsPermission: data.needsPermission,
      installedFitnessAppNames: data.installedFitnessAppNames,
      dataSourceLabels: data.dataSourceLabels,
      lastDataUpdateMillis: data.lastDataUpdateMillis,
      lastDataSourceLabel: data.lastDataSourceLabel,
      dataMayBeStale: data.dataMayBeStale,
      stepsPermissionGranted: data.stepsPermissionGranted,
      sleepPermissionGranted: data.sleepPermissionGranted,
      partialPermissionHint: data.partialPermissionHint,
      sleepIsManual: true,
      stepsDataSourceLine: data.stepsDataSourceLine,
      sleepDataSourceLine: data.sleepDataSourceLine,
    );
  }

  static Future<HealthConnectData> _enrichFromPlugin(HealthConnectData data) async {
    try {
      final health = Health();
      await health.configure();
      if (!_pluginSdkUsable(await health.getHealthConnectSdkStatus())) {
        return data;
      }
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final currentSteps = data.stepsToday ?? 0;
      final fromPluginSteps = await health.getTotalStepsInInterval(startOfDay, now);
      // Keep native phone records only; plugin fills when native has zero.
      final bestSteps = currentSteps > 0 ? currentSteps : (fromPluginSteps ?? 0);

      final currentSleep = data.sleepHoursLastNight;
      final fromPluginSleep = await _readSleepHours(health, startOfDay, now);
      final bestSleep = (currentSleep != null && currentSleep > 0)
          ? currentSleep
          : fromPluginSleep;

      if (bestSteps == currentSteps && bestSleep == data.sleepHoursLastNight) {
        return data;
      }

      final hasData = bestSteps > 0 || (bestSleep != null && bestSleep > 0);
      final stepsLine = data.stepsDataSourceLine ??
          (bestSteps > 0 && currentSteps <= 0
              ? "Steps from Health Connect · plugin records · today"
              : null);
      final sleepLine = data.sleepDataSourceLine ??
          (bestSleep != null && bestSleep > 0 && (currentSleep == null || currentSleep <= 0)
              ? "Sleep from Health Connect · plugin records · today"
              : null);
      return HealthConnectData(
        sdkStatus: data.sdkStatus,
        permissionsGranted: data.permissionsGranted,
        stepsToday: bestSteps,
        sleepHoursLastNight: bestSleep,
        stepsLast7Days: data.stepsLast7Days,
        hasData: hasData,
        errorMessage: hasData ? null : data.errorMessage,
        needsInstall: data.needsInstall,
        needsPermission: data.needsPermission,
        installedFitnessAppNames: data.installedFitnessAppNames,
        dataSourceLabels: data.dataSourceLabels,
        lastDataUpdateMillis: data.lastDataUpdateMillis,
        lastDataSourceLabel: data.lastDataSourceLabel,
        dataMayBeStale: data.dataMayBeStale,
        stepsPermissionGranted: data.stepsPermissionGranted,
        sleepPermissionGranted: data.sleepPermissionGranted,
        partialPermissionHint: data.partialPermissionHint,
        sleepIsManual: data.sleepIsManual,
        stepsDataSourceLine: stepsLine,
        sleepDataSourceLine: sleepLine,
      );
    } catch (_) {
      return data;
    }
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
        installedFitnessAppNames: data.installedFitnessAppNames,
        dataSourceLabels: data.dataSourceLabels,
        lastDataUpdateMillis: data.lastDataUpdateMillis,
        lastDataSourceLabel: data.lastDataSourceLabel,
        dataMayBeStale: data.dataMayBeStale,
        stepsPermissionGranted: data.stepsPermissionGranted,
        sleepPermissionGranted: data.sleepPermissionGranted,
        partialPermissionHint: data.partialPermissionHint,
        sleepIsManual: data.sleepIsManual,
        stepsDataSourceLine: data.stepsDataSourceLine,
        sleepDataSourceLine: data.sleepDataSourceLine,
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
      return _applyManualSleepFallback(
        HealthConnectData(
          sdkStatus: sdk,
          permissionsGranted: true,
          stepsToday: stepsToday,
          sleepHoursLastNight: sleepHours,
          stepsLast7Days: steps7d,
          hasData: hasData,
          errorMessage: hasData
              ? null
              : "Health Connect reports ${stepsToday > 0 ? '$stepsToday steps' : 'no steps'} so far today. "
                  "If your fitness app shows more, open it and sync to Health Connect, then pull to refresh.",
        ),
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
      final usage = UsageStatsService();

      // System dialog: Steps + Sleep together (fixes HC showing only Steps).
      final native = await usage.requestHealthConnectPermissions();
      if (native != null && native["error"] != "health_connect_not_installed") {
        if (native["allGranted"] == true) {
          await _openFitnessAppForSyncIfNeeded(usage);
          return const HealthPermissionRequestResult(granted: true);
        }
        if (native["grantedSteps"] == true && native["grantedSleep"] != true) {
          await usage.openHealthConnectPermissions();
          return const HealthPermissionRequestResult(
            openedSettings: true,
            message:
                "Steps allowed. In Health Connect, turn on Sleep for this app, then tap Refresh.",
          );
        }
      }

      final health = Health();
      await health.configure();
      final sdk = await health.getHealthConnectSdkStatus();
      if (_pluginSdkUsable(sdk)) {
        var granted = await health.hasPermissions(permissionTypes, permissions: _permissionAccess);
        if (granted != true) {
          granted = await health.requestAuthorization(permissionTypes, permissions: _permissionAccess);
        }
        if (granted == true) {
          await _openFitnessAppForSyncIfNeeded(usage);
          return const HealthPermissionRequestResult(granted: true);
        }
      }

      final opened = await usage.openHealthConnectPermissions();
      final summary = await usage.readHealthSummary();
      final steps = summary?["stepsPermissionGranted"] == true;
      final sleep = summary?["sleepPermissionGranted"] == true;
      if (steps && sleep) {
        await _openFitnessAppForSyncIfNeeded(usage);
        return const HealthPermissionRequestResult(granted: true);
      }
      if (steps && !sleep) {
        return HealthPermissionRequestResult(
          openedSettings: opened,
          message:
              "Allow Sleep (not only Steps) for Life Pattern Tracker in Health Connect, then Refresh.",
        );
      }

      return HealthPermissionRequestResult(
        openedSettings: opened,
        denied: !opened,
        message: opened
            ? "Allow Steps and Sleep for this app in Health Connect, then tap Refresh."
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

  static Future<void> _openFitnessAppForSyncIfNeeded(UsageStatsService usage) async {
    final summary = await usage.readHealthSummary();
    if (summary == null) return;
    final installed = _parseInstalledFitnessNames(summary);
    if (installed.isEmpty) return;
    final sleepPerm = summary["sleepPermissionGranted"] == true;
    final sleepHours = summary["sleepHours"];
    final hasSleep = sleepHours is num && sleepHours > 0;
    if (!sleepPerm || !hasSleep) {
      await usage.openPrimaryFitnessApp();
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
    final sleepStart = startOfDay.subtract(const Duration(days: 1));

    double? bestSessionHours;
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

      if (types.first == HealthDataType.SLEEP_SESSION) {
        for (final p in points) {
          final hours = p.dateTo.difference(p.dateFrom).inMinutes / 60.0;
          if (hours > (bestSessionHours ?? 0)) bestSessionHours = hours;
        }
        continue;
      }

      var segmentHours = 0.0;
      for (final p in points) {
        segmentHours += p.dateTo.difference(p.dateFrom).inMinutes / 60.0;
      }
      if (segmentHours > (bestSessionHours ?? 0)) bestSessionHours = segmentHours;
    }
    return bestSessionHours;
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
