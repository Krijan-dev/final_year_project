import "dart:convert";

import "package:http/http.dart" as http;
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

/// Uploads habit/mood/log snapshot for the current week to MongoDB via the API.
class HabitRemoteService {
  HabitRemoteService();

  static const String _baseUrl = String.fromEnvironment("API_BASE_URL");

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  Future<void> uploadSnapshot({
    required String userEmail,
    required String weekKey,
    required Map<String, dynamic> payload,
  }) async {
    if (!isConfigured) return;
    final token = AuthTokenStore.read();
    if (token.isEmpty) return;
    final base = _baseUrl.trim().replaceAll(RegExp(r"/$"), "");
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
