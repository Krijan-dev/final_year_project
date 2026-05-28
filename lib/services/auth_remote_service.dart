import "dart:convert";
import "dart:async";

import "package:http/http.dart" as http;
import "package:life_pattern_tracker/services/api_config.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

class AuthRemoteResult {
  const AuthRemoteResult({this.email, this.token, this.error});

  final String? email;
  final String? token;
  final String? error;

  bool get ok => error == null && email != null && token != null;
}

class SendVerificationResult {
  const SendVerificationResult({
    this.ok = false,
    this.error,
    this.devCode,
    this.devHint,
    this.smtpConfigured = true,
  });

  final bool ok;
  final String? error;
  final String? devCode;
  final String? devHint;
  final bool smtpConfigured;
}

class VerifyEmailResult {
  const VerifyEmailResult({
    this.ok = false,
    this.error,
    this.verificationToken,
  });

  final bool ok;
  final String? error;
  final String? verificationToken;
}

/// Register/login against MongoDB via `server/` (see docs/MONGODB.md).
class AuthRemoteService {
  static bool get isConfigured => ApiConfig.isConfigured;
  static const Duration _requestTimeout = Duration(seconds: 20);

  static Uri _uri(String path) {
    final base = ApiConfig.baseUrl;
    return Uri.parse("$base$path");
  }

  static Future<SendVerificationResult> sendVerificationCode({
    required String email,
  }) async {
    if (!isConfigured) {
      return const SendVerificationResult(error: "API_BASE_URL is not configured.");
    }
    try {
      final res = await http.post(
        _uri("/api/v1/auth/send-verification"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({"email": email.trim().toLowerCase()}),
      ).timeout(_requestTimeout);
      final body = _decode(res.body);
      if (res.statusCode >= 400) {
        final serverError = body?["error"] as String?;
        if (res.statusCode == 404) {
          return const SendVerificationResult(
            error:
                "Email verification is not on the live API yet. Deploy the latest server/ code to Render and redeploy.",
          );
        }
        return SendVerificationResult(
          error: serverError ?? "Could not send code (${res.statusCode})",
        );
      }
      final smtpConfigured = body?["smtpConfigured"] == true;
      final devCode = body?["devCode"] as String?;
      final devHint = body?["devHint"] as String?;
      if (!smtpConfigured && (devCode == null || devCode.isEmpty)) {
        return const SendVerificationResult(
          error:
              "Email service is not configured on the server, so verification emails cannot be sent yet.",
          smtpConfigured: false,
        );
      }
      return SendVerificationResult(
        ok: true,
        devCode: devCode,
        devHint: devHint,
        smtpConfigured: smtpConfigured,
      );
    } on TimeoutException catch (e, st) {
      AppLog.e("sendVerificationCode timeout", error: e, stackTrace: st);
      return const SendVerificationResult(
        error: "Request timed out. Check your internet/API server and try again.",
      );
    } catch (e, st) {
      AppLog.e("sendVerificationCode failed", error: e, stackTrace: st);
      return const SendVerificationResult(error: "Cannot reach API. Is the server running?");
    }
  }

  static Future<VerifyEmailResult> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    if (!isConfigured) {
      return const VerifyEmailResult(error: "API_BASE_URL is not configured.");
    }
    try {
      final res = await http.post(
        _uri("/api/v1/auth/verify-email"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
          "code": code.trim(),
        }),
      );
      final body = _decode(res.body);
      if (res.statusCode >= 400) {
        return VerifyEmailResult(error: body?["error"] as String? ?? "Verification failed");
      }
      final token = body?["verificationToken"] as String?;
      if (token == null || token.isEmpty) {
        return const VerifyEmailResult(error: "Invalid server response.");
      }
      return VerifyEmailResult(ok: true, verificationToken: token);
    } catch (e, st) {
      AppLog.e("verifyEmailCode failed", error: e, stackTrace: st);
      return const VerifyEmailResult(error: "Cannot reach API. Is the server running?");
    }
  }

  static Future<AuthRemoteResult> register({
    required String email,
    required String password,
    required String verificationToken,
  }) async {
    return _auth(
      path: "/api/v1/auth/register",
      body: {
        "email": email.trim().toLowerCase(),
        "password": password,
        "verificationToken": verificationToken,
      },
      expectCreated: true,
    );
  }

  static Future<SendVerificationResult> sendForgotPasswordCode({
    required String email,
  }) async {
    if (!isConfigured) {
      return const SendVerificationResult(error: "API_BASE_URL is not configured.");
    }
    try {
      final res = await http.post(
        _uri("/api/v1/auth/forgot-password"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({"email": email.trim().toLowerCase()}),
      ).timeout(_requestTimeout);
      final body = _decode(res.body);
      if (res.statusCode >= 400) {
        final serverError = body?["error"] as String?;
        if (res.statusCode == 404) {
          return const SendVerificationResult(
            error:
                "Password reset is not on the live API yet. Deploy the latest server/ code to Render.",
          );
        }
        return SendVerificationResult(
          error: serverError ?? "Could not send reset code (${res.statusCode})",
        );
      }
      final smtpConfigured = body?["smtpConfigured"] == true;
      final devCode = body?["devCode"] as String?;
      final devHint = body?["devHint"] as String?;
      if (!smtpConfigured && (devCode == null || devCode.isEmpty)) {
        return const SendVerificationResult(
          error:
              "Email service is not configured on the server, so reset codes cannot be sent yet.",
          smtpConfigured: false,
        );
      }
      return SendVerificationResult(
        ok: true,
        devCode: devCode,
        devHint: devHint,
        smtpConfigured: smtpConfigured,
      );
    } on TimeoutException catch (e, st) {
      AppLog.e("sendForgotPasswordCode timeout", error: e, stackTrace: st);
      return const SendVerificationResult(
        error: "Request timed out. Check your internet/API server and try again.",
      );
    } catch (e, st) {
      AppLog.e("sendForgotPasswordCode failed", error: e, stackTrace: st);
      return const SendVerificationResult(error: "Cannot reach API. Is the server running?");
    }
  }

  static Future<VerifyEmailResult> verifyResetCode({
    required String email,
    required String code,
  }) async {
    if (!isConfigured) {
      return const VerifyEmailResult(error: "API_BASE_URL is not configured.");
    }
    try {
      final res = await http.post(
        _uri("/api/v1/auth/verify-reset-code"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode({
          "email": email.trim().toLowerCase(),
          "code": code.trim(),
        }),
      );
      final body = _decode(res.body);
      if (res.statusCode >= 400) {
        return VerifyEmailResult(error: body?["error"] as String? ?? "Verification failed");
      }
      final token = body?["resetToken"] as String?;
      if (token == null || token.isEmpty) {
        return const VerifyEmailResult(error: "Invalid server response.");
      }
      return VerifyEmailResult(ok: true, verificationToken: token);
    } catch (e, st) {
      AppLog.e("verifyResetCode failed", error: e, stackTrace: st);
      return const VerifyEmailResult(error: "Cannot reach API. Is the server running?");
    }
  }

  static Future<AuthRemoteResult> resetPassword({
    required String email,
    required String password,
    required String resetToken,
  }) async {
    return _auth(
      path: "/api/v1/auth/reset-password",
      body: {
        "email": email.trim().toLowerCase(),
        "password": password,
        "resetToken": resetToken,
      },
    );
  }

  static Future<AuthRemoteResult> login({
    required String email,
    required String password,
  }) async {
    return _auth(
      path: "/api/v1/auth/login",
      body: {
        "email": email.trim().toLowerCase(),
        "password": password,
      },
    );
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

  static Future<String?> deleteAccount({
    required String token,
    required String password,
  }) async {
    if (!isConfigured) return "API_BASE_URL is not configured.";
    if (token.isEmpty) return "Missing session token.";
    if (password.isEmpty) return "Password is required.";
    try {
      final res = await http.delete(
        _uri("/api/v1/users/me"),
        headers: _headers(token),
        body: jsonEncode({"password": password}),
      );
      final decoded = _decode(res.body);
      if (res.statusCode != 200) {
        return decoded?["error"] as String? ?? "Server error (${res.statusCode})";
      }
      return null;
    } catch (e, st) {
      AppLog.e("AuthRemoteService.deleteAccount failed", error: e, stackTrace: st);
      return "Cannot reach API. Is the server running?";
    }
  }

  static Map<String, String> authHeaders(String token) => _headers(token);

  static Map<String, String> _headers(String token) => {
        "Content-Type": "application/json; charset=utf-8",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      };

  static Future<AuthRemoteResult> _auth({
    required String path,
    required Map<String, dynamic> body,
    bool expectCreated = false,
  }) async {
    if (!isConfigured) {
      return const AuthRemoteResult(error: "API_BASE_URL is not configured.");
    }
    try {
      final res = await http.post(
        _uri(path),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: jsonEncode(body),
      );
      final decoded = _decode(res.body);
      final errMsg = decoded?["error"] as String?;
      if (expectCreated ? res.statusCode != 201 : res.statusCode != 200) {
        return AuthRemoteResult(
          error: errMsg ?? "Server error (${res.statusCode})",
        );
      }
      final token = decoded?["token"] as String?;
      final returnedEmail = decoded?["email"] as String?;
      if (token == null || token.isEmpty || returnedEmail == null) {
        return const AuthRemoteResult(error: "Invalid server response.");
      }
      return AuthRemoteResult(email: returnedEmail, token: token);
    } catch (e, st) {
      AppLog.e("AuthRemoteService request failed", error: e, stackTrace: st);
      return const AuthRemoteResult(error: "Cannot reach API. Is the server running?");
    }
  }

  static Map<String, dynamic>? _decode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}
