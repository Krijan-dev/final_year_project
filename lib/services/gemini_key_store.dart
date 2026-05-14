import "package:flutter/foundation.dart";
import "package:hive_flutter/hive_flutter.dart";

/// Hive box opened in [main]. Used only in debug for a runtime Gemini key (hot reload friendly).
const String kAppSettingsBoxName = "app_settings";
const String kGeminiApiKeyHiveKey = "gemini_api_key";

abstract final class GeminiKeyStore {
  static String readDebugOverride() {
    if (!kDebugMode) return "";
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return "";
    final raw = Hive.box<dynamic>(kAppSettingsBoxName).get(kGeminiApiKeyHiveKey);
    if (raw is! String) return "";
    return raw.trim();
  }

  /// Debug-only. Persists until cleared; survives hot reload (unlike compile-time defines).
  static Future<void> writeDebugOverride(String? key) async {
    if (!kDebugMode) return;
    final box = Hive.box<dynamic>(kAppSettingsBoxName);
    final trimmed = key?.trim() ?? "";
    if (trimmed.isEmpty) {
      await box.delete(kGeminiApiKeyHiveKey);
    } else {
      await box.put(kGeminiApiKeyHiveKey, trimmed);
    }
  }
}
