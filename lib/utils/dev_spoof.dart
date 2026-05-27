import "package:flutter/foundation.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";

enum DevSpoofLevel { off, best, medium, bad }

/// Enables fake / demo data so you can test the UI without granting permissions.
///
/// Default enable is driven by `DEV_SPOOF_DATA` (bool) in `.env`, but you can
/// change the level from the app Settings page (stored in Hive).
abstract final class DevSpoof {
  static const String _hiveKey = "dev_spoof_level";

  static DevSpoofLevel get level {
    if (!kDebugMode) return DevSpoofLevel.off;

    // 1) Prefer Hive value set from the in-app Settings page.
    if (Hive.isBoxOpen(kAppSettingsBoxName)) {
      final raw = Hive.box<dynamic>(kAppSettingsBoxName).get(_hiveKey);
      if (raw is int) {
        for (final l in DevSpoofLevel.values) {
          if (l.index == raw) return l;
        }
        return DevSpoofLevel.off;
      }
      if (raw is String) {
        final v = raw.trim().toLowerCase();
        if (v == "best") return DevSpoofLevel.best;
        if (v == "medium") return DevSpoofLevel.medium;
        if (v == "bad") return DevSpoofLevel.bad;
        if (v == "off" || v == "0") return DevSpoofLevel.off;
      }
    }

    // 2) Fallback: boolean enable from `.env` (best by default).
    final raw = dotenv.maybeGet("DEV_SPOOF_DATA");
    if (raw == null) return DevSpoofLevel.off;
    final v = raw.trim().toLowerCase();
    final enabled = v == "1" || v == "true" || v == "yes" || v == "on";
    return enabled ? DevSpoofLevel.best : DevSpoofLevel.off;
  }

  static bool get enabled => level != DevSpoofLevel.off;

  static void setLevel(DevSpoofLevel newLevel) {
    if (!kDebugMode) return;
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return;
    final box = Hive.box<dynamic>(kAppSettingsBoxName);
    box.put(_hiveKey, newLevel.index);
  }
}

