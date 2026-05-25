import "dart:convert";

import "package:http/http.dart" as http;
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/utils/app_log.dart";

class SupportMessageDto {
  const SupportMessageDto({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String sender;
  final String text;
  final DateTime createdAt;

  bool get isUser => sender == "user";

  factory SupportMessageDto.fromJson(Map<String, dynamic> json) {
    return SupportMessageDto(
      id: json["id"] as String? ?? "",
      sender: json["sender"] as String? ?? "admin",
      text: json["text"] as String? ?? "",
      createdAt: DateTime.tryParse(json["createdAt"] as String? ?? "") ?? DateTime.now(),
    );
  }
}

class SupportConversationDto {
  const SupportConversationDto({
    required this.id,
    required this.status,
    required this.userId,
  });

  final String id;
  final String status;
  final String userId;

  factory SupportConversationDto.fromJson(Map<String, dynamic> json) {
    return SupportConversationDto(
      id: json["id"] as String? ?? "",
      status: json["status"] as String? ?? "waiting",
      userId: json["userId"] as String? ?? "",
    );
  }
}

/// Live support chat with admins (polling API).
class SupportRemoteService {
  static const String _baseUrl = String.fromEnvironment("API_BASE_URL");

  static bool get isConfigured => _baseUrl.trim().isNotEmpty;

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = _baseUrl.trim().replaceAll(RegExp(r"/$"), "");
    return Uri.parse("$base$path").replace(queryParameters: query);
  }

  static Map<String, String> get _headers {
    final token = AuthTokenStore.read();
    return AuthRemoteService.authHeaders(token);
  }

  Future<SupportConversationDto?> startConversation() async {
    if (!isConfigured) return null;
    try {
      final res = await http.post(_uri("/api/v1/support/conversations"), headers: _headers);
      final body = _decode(res.body);
      if (res.statusCode >= 400) {
        AppLog.e("SupportRemoteService.start: ${res.statusCode}", error: body?["error"]);
        return null;
      }
      final conv = body?["conversation"] as Map<String, dynamic>?;
      if (conv == null) return null;
      return SupportConversationDto.fromJson(conv);
    } catch (e, st) {
      AppLog.e("SupportRemoteService.start failed", error: e, stackTrace: st);
      return null;
    }
  }

  Future<({SupportConversationDto? conversation, List<SupportMessageDto> messages})> fetchMessages({
    DateTime? since,
  }) async {
    if (!isConfigured) {
      return (conversation: null, messages: <SupportMessageDto>[]);
    }
    try {
      final query = since != null ? {"since": since.toUtc().toIso8601String()} : null;
      final res = await http.get(_uri("/api/v1/support/messages", query), headers: _headers);
      final body = _decode(res.body);
      if (res.statusCode >= 400) {
        AppLog.e("SupportRemoteService.fetch: ${res.statusCode}", error: body?["error"]);
        return (conversation: null, messages: <SupportMessageDto>[]);
      }
      final convRaw = body?["conversation"] as Map<String, dynamic>?;
      final list = (body?["messages"] as List?) ?? [];
      return (
        conversation: convRaw != null ? SupportConversationDto.fromJson(convRaw) : null,
        messages: list
            .whereType<Map>()
            .map((e) => SupportMessageDto.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
    } catch (e, st) {
      AppLog.e("SupportRemoteService.fetch failed", error: e, stackTrace: st);
      return (conversation: null, messages: <SupportMessageDto>[]);
    }
  }

  Future<SupportMessageDto?> sendMessage(String text) async {
    if (!isConfigured) return null;
    try {
      final res = await http.post(
        _uri("/api/v1/support/messages"),
        headers: _headers,
        body: jsonEncode({"text": text}),
      );
      final body = _decode(res.body);
      if (res.statusCode >= 400) {
        AppLog.e("SupportRemoteService.send: ${res.statusCode}", error: body?["error"]);
        return null;
      }
      final msg = body?["message"] as Map<String, dynamic>?;
      if (msg == null) return null;
      return SupportMessageDto.fromJson(msg);
    } catch (e, st) {
      AppLog.e("SupportRemoteService.send failed", error: e, stackTrace: st);
      return null;
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
