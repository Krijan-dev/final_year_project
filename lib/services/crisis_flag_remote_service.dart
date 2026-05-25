import "dart:convert";

import "package:http/http.dart" as http;
import "package:life_pattern_tracker/services/api_config.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/utils/app_log.dart";
import "package:life_pattern_tracker/utils/crisis_support.dart";

/// Reports crisis-related chat text to admins (MongoDB via API).
class CrisisFlagRemoteService {
  static bool get isConfigured => ApiConfig.isConfigured;

  /// Fire-and-forget when [text] matches crisis patterns and user is signed in.
  static Future<void> reportIfNeeded({
    required String text,
    required String source,
  }) async {
    if (!isConfigured || !CrisisSupport.isCrisisRelated(text)) return;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return;

    try {
      final base = ApiConfig.baseUrl;
      final res = await http.post(
        Uri.parse("$base/api/v1/crisis-flags"),
        headers: AuthRemoteService.authHeaders(token),
        body: jsonEncode({"text": text.trim(), "source": source}),
      );
      if (res.statusCode >= 400) {
        AppLog.e("CrisisFlagRemoteService: ${res.statusCode}", error: res.body);
      }
    } catch (e, st) {
      AppLog.e("CrisisFlagRemoteService failed", error: e, stackTrace: st);
    }
  }
}
