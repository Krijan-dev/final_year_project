import "dart:convert";

import "package:http/http.dart" as http;
import "package:life_pattern_tracker/utils/app_log.dart";

class AuthRemoteResult {
  const AuthRemoteResult({this.email, this.token, this.error});

  final String? email;
  final String? token;
  final String? error;

  bool get ok => error == null && email != null && token != null;
}

/// Register/login against MongoDB via `server/` (see docs/MONGODB.md).
class AuthRemoteService {
  static const String _baseUrl = String.fromEnvironment("API_BASE_URL");

  static bool get isConfigured => _baseUrl.trim().isNotEmpty;

  static Uri _uri(String path) {
    final base = _baseUrl.trim().replaceAll(RegExp(r"/$"), "");
    return Uri.parse("$base$path");
  }

  static Future<AuthRemoteResult> register({
    required String email,
    required String password,
  }) async {
    return _auth(
      path: "/api/v1/auth/register",
      email: email,
      password: password,
      expectCreated: true,
    );
  }

  static Future<AuthRemoteResult> login({
    required String email,
    required String password,
  }) async {
    return _auth(path: "/api/v1/auth/login", email: email, password: password);
  }

  static Future<void> logout({required String token}) async {
    if (!isConfigured || token.isEmpty) return;
    try {
      await http.post(
        _uri("/api/v1/auth/logout"),
        headers: _headers(token),
      );
    } catch (e, st) {
      AppLog.e("AuthRemoteService.logout failed", error: e, stackTrace: st);
    }
  }

  static Map<String, String> authHeaders(String token) => _headers(token);

  static Map<String, String> _headers(String token) => {
        "Content-Type": "application/json; charset=utf-8",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

  static Future<AuthRemoteResult> _auth({
    required String path,
    required String email,
    required String password,
    bool expectCreated = false,
  }) async {
    if (!isConfigured) {
      return const AuthRemoteResult(error: "API_BASE_URL is not configured.");
    }
    try {
      final res = await http.post(
        _uri(path),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({"email": email, "password": password}),
      );
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {
        body = null;
      }
      final errMsg = body?["error"] as String?;
      if (expectCreated ? res.statusCode != 201 : res.statusCode != 200) {
        return AuthRemoteResult(
          error: errMsg ?? "Server error (${res.statusCode})",
        );
      }
      final token = body?["token"] as String?;
      final returnedEmail = body?["email"] as String?;
      if (token == null || token.isEmpty || returnedEmail == null) {
        return const AuthRemoteResult(error: "Invalid server response.");
      }
      return AuthRemoteResult(email: returnedEmail, token: token);
    } catch (e, st) {
      AppLog.e("AuthRemoteService request failed", error: e, stackTrace: st);
      return AuthRemoteResult(error: "Cannot reach API. Is the server running?");
    }
  }
}
