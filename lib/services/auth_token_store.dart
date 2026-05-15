import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";

const String kAuthTokenHiveKey = "auth_session_token";

/// API session token after login/register (MongoDB-backed auth).
abstract final class AuthTokenStore {
  static String read() {
    if (!Hive.isBoxOpen(kAppSettingsBoxName)) return "";
    final raw = Hive.box<dynamic>(kAppSettingsBoxName).get(kAuthTokenHiveKey);
    return raw is String ? raw.trim() : "";
  }

  static Future<void> write(String? token) async {
    final box = Hive.box<dynamic>(kAppSettingsBoxName);
    final trimmed = token?.trim() ?? "";
    if (trimmed.isEmpty) {
      await box.delete(kAuthTokenHiveKey);
    } else {
      await box.put(kAuthTokenHiveKey, trimmed);
    }
  }
}
