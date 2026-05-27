import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/models/app_screen_time_limit.dart";
import "package:life_pattern_tracker/services/app_screen_time_limit_storage.dart";
import "package:life_pattern_tracker/services/screen_time_background_service.dart";
import "package:life_pattern_tracker/services/screen_time_notification_service.dart";

class ScreenTimeLimitsState {
  const ScreenTimeLimitsState({
    this.loading = false,
    this.error,
    this.limits = const {},
  });

  final bool loading;
  final String? error;
  final Map<String, AppScreenTimeLimit> limits;

  ScreenTimeLimitsState copyWith({
    bool? loading,
    String? error,
    Map<String, AppScreenTimeLimit>? limits,
  }) {
    return ScreenTimeLimitsState(
      loading: loading ?? this.loading,
      error: error,
      limits: limits ?? this.limits,
    );
  }
}

class ScreenTimeLimitsNotifier extends StateNotifier<ScreenTimeLimitsState> {
  ScreenTimeLimitsNotifier({
    required AppScreenTimeLimitStorage storage,
    required ScreenTimeNotificationService notifications,
    required ScreenTimeBackgroundService background,
  })  : _storage = storage,
        _notifications = notifications,
        _background = background,
        super(const ScreenTimeLimitsState()) {
    Future.microtask(() async {
      await _load();
    });
  }

  final AppScreenTimeLimitStorage _storage;
  final ScreenTimeNotificationService _notifications;
  final ScreenTimeBackgroundService _background;

  Future<void> _load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final limits = await _storage.loadAll();
      await _background.syncLimits(limits);
      state = state.copyWith(loading: false, limits: limits, error: null);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() => _load();

  List<AppScreenTimeLimit> get limitsAsList =>
      state.limits.values.toList(growable: false);

  Future<void> upsertLimit({
    required String packageName,
    required String displayName,
    required int limitMinutesPerDay,
    bool notifyWhenExceeded = true,
  }) async {
    final sanitizedName = displayName.trim();
    if (packageName.trim().isEmpty) return;
    if (limitMinutesPerDay < AppScreenTimeLimit.minMinutes) return;

    final limit = AppScreenTimeLimit(
      packageName: packageName.trim(),
      displayName: sanitizedName,
      limitMinutesPerDay: limitMinutesPerDay,
      notifyWhenExceeded: notifyWhenExceeded,
    );

    state = state.copyWith(loading: true, error: null);
    try {
      // If they enabled alerts, ask for permission before saving.
      // If denied, we still save the limit but with alerts disabled.
      var finalNotify = limit.notifyWhenExceeded;
      if (finalNotify) {
        final ok = await _notifications.ensureAndroidPostPermission();
        if (!ok) finalNotify = false;
      }

      await _storage.save(limit.copyWith(notifyWhenExceeded: finalNotify));
      final updated = await _storage.loadAll();
      await _background.syncLimits(updated);
      state = state.copyWith(loading: false, limits: updated);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<bool> setNotificationsEnabled({
    required String packageName,
    required bool enabled,
  }) async {
    final existing = state.limits[packageName];
    if (existing == null) return false;
    if (!enabled) {
      await _storage.save(
        existing.copyWith(notifyWhenExceeded: false),
      );
      final updated = await _storage.loadAll();
      await _background.syncLimits(updated);
      state = state.copyWith(limits: updated);
      return true;
    }

    // Enabling notifications requires permission.
    final ok = await _notifications.ensureAndroidPostPermission();
    if (!ok) return false;

    await _storage.save(
      existing.copyWith(notifyWhenExceeded: true),
    );
    final updated = await _storage.loadAll();
    await _background.syncLimits(updated);
    state = state.copyWith(limits: updated);
    return true;
  }

  Future<void> removeLimit(String packageName) async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _storage.remove(packageName);
      final updated = await _storage.loadAll();
      await _background.syncLimits(updated);
      state = state.copyWith(loading: false, limits: updated);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }
}

final screenTimeLimitsProvider = StateNotifierProvider<
    ScreenTimeLimitsNotifier, ScreenTimeLimitsState>((ref) {
  return ScreenTimeLimitsNotifier(
    storage: AppScreenTimeLimitStorage(),
    notifications: ScreenTimeNotificationService.instance,
    background: ScreenTimeBackgroundService(),
  );
});

