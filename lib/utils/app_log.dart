import "package:flutter/foundation.dart";

/// Logging that is disabled in profile/release builds (no terminal spam in production).
abstract final class AppLog {
  static void d(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;
    debugPrint(message);
    if (error != null) {
      debugPrint("$error");
    }
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
