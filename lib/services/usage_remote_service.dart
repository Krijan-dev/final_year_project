import "dart:convert";

import "package:http/http.dart" as http;
import "package:life_pattern_tracker/models/daily_usage_model.dart";
import "package:life_pattern_tracker/services/api_config.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

/// Syncs usage JSON to a small REST API backed by MongoDB (see `server/` and docs/MONGODB.md).
///
/// Set at compile time, e.g. in `.env`:
/// `API_BASE_URL=http://10.0.2.2:3000` (Android emulator → host).
class UsageRemoteService {
  UsageRemoteService();

  bool get isConfigured => ApiConfig.isConfigured;

  /// Fire-and-forget upload of one day for [userEmail] (signed-in account).
  Future<void> uploadUsageDay({
    required String userEmail,
    required DailyUsageModel day,
  }) async {
    if (!isConfigured) return;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return;
    final base = ApiConfig.baseUrl;
    final uid = Uri.encodeComponent(userEmail);
    final dayKey = Uri.encodeComponent(_dayKey(day));
    final url = Uri.parse("$base/api/v1/users/$uid/usage-days/$dayKey");
    try {
      final res = await http.put(
        url,
        headers: AuthRemoteService.authHeaders(token),
        body: jsonEncode(day.toMap()),
      );
      if (res.statusCode >= 400) {
        AppLog.e("UsageRemoteService: PUT ${res.statusCode}", error: res.body);
      }
    } catch (e, st) {
      AppLog.e("UsageRemoteService upload failed", error: e, stackTrace: st);
    }
  }

  static String _dayKey(DailyUsageModel m) {
    final d = DateTime(m.date.year, m.date.month, m.date.day);
    return d.toIso8601String().split("T").first;
  }
}
