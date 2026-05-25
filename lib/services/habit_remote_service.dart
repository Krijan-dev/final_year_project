import "dart:convert";

import "package:http/http.dart" as http;
import "package:life_pattern_tracker/services/api_config.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

/// Uploads habit/mood/log snapshot for the current week to MongoDB via the API.
class HabitRemoteService {
  HabitRemoteService();

  bool get isConfigured => ApiConfig.isConfigured;

  Future<Map<String, dynamic>?> fetchLatestSnapshot({required String userEmail}) async {
    if (!isConfigured) return null;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return null;
    final uid = Uri.encodeComponent(userEmail);
    final url = Uri.parse("${ApiConfig.baseUrl}/api/v1/users/$uid/habit-snapshots/latest");
    try {
      final res = await http.get(url, headers: AuthRemoteService.authHeaders(token));
      if (res.statusCode >= 404) {
        if (res.statusCode != 404) {
          AppLog.e("HabitRemoteService: GET latest ${res.statusCode}", error: res.body);
        }
        return null;
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>?;
      final snap = body?["snapshot"];
      if (snap is! Map) return null;
      return Map<String, dynamic>.from(snap);
    } catch (e, st) {
      AppLog.e("HabitRemoteService fetch failed", error: e, stackTrace: st);
      return null;
    }
  }

  Future<void> uploadSnapshot({
    required String userEmail,
    required String weekKey,
    required Map<String, dynamic> payload,
  }) async {
    if (!isConfigured) return;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return;
    final base = ApiConfig.baseUrl;
    final uid = Uri.encodeComponent(userEmail);
    final wk = Uri.encodeComponent(weekKey);
    final url = Uri.parse("$base/api/v1/users/$uid/habit-snapshot/$wk");
    try {
      final res = await http.put(
        url,
        headers: AuthRemoteService.authHeaders(token),
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 400) {
        AppLog.e("HabitRemoteService: PUT ${res.statusCode}", error: res.body);
      }
    } catch (e, st) {
      AppLog.e("HabitRemoteService upload failed", error: e, stackTrace: st);
    }
  }
}
