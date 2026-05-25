import "package:flutter_dotenv/flutter_dotenv.dart";

/// API base URL from compile-time defines or bundled `.env` (see [main]).
abstract final class ApiConfig {
  static const String _fromDefine = String.fromEnvironment("API_BASE_URL");

  static String get baseUrl {
    final define = _fromDefine.trim();
    if (define.isNotEmpty) {
      return _stripTrailingSlash(define);
    }
    final file = dotenv.maybeGet("API_BASE_URL")?.trim() ?? "";
    return _stripTrailingSlash(file);
  }

  static bool get isConfigured => baseUrl.isNotEmpty;

  static String _stripTrailingSlash(String url) =>
      url.replaceAll(RegExp(r"/$"), "");
}
