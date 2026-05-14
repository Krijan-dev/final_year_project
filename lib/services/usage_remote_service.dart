import "dart:convert";

import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:life_pattern_tracker/models/daily_usage_model.dart";

/// Syncs usage JSON to a small REST API backed by MongoDB (see `server/` and docs/MONGODB.md).
///
/// Set at compile time, e.g. in `.env`:
/// `API_BASE_URL=http://10.0.2.2:3000` (Android emulator → host).
class UsageRemoteService {
  UsageRemoteService();

  static const String _baseUrl = String.fromEnvironment("API_BASE_URL");

  bool get isConfigured => _baseUrl.trim().isNotEmpty;

  /// Fire-and-forget upload of one day for [userEmail] (signed-in account).
  Future<void> uploadUsageDay({
    required String userEmail,
    required DailyUsageModel day,
  }) async {
    if (!isConfigured) return;
    final base = _baseUrl.trim().replaceAll(RegExp(r"/$"), "");
    final uid = Uri.encodeComponent(userEmail);
    final dayKey = Uri.encodeComponent(_dayKey(day));
    final url = Uri.parse("$base/api/v1/users/$uid/usage-days/$dayKey");
    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode(day.toMap()),
      );
      if (res.statusCode >= 400) {
        debugPrint("UsageRemoteService: PUT ${res.statusCode} ${res.body}");
      }
    } catch (e, st) {
      debugPrint("UsageRemoteService: $e");
      debugPrintStack(stackTrace: st);
    }
  }

  static String _dayKey(DailyUsageModel m) {
    final d = DateTime(m.date.year, m.date.month, m.date.day);
    return d.toIso8601String().split("T").first;
  }
}
