import "package:google_generative_ai/google_generative_ai.dart";

class GeminiService {
  GeminiService._();

  static const String _apiKey = String.fromEnvironment("GEMINI_API_KEY");
  static const List<String> _modelCandidates = [
    "gemini-2.0-flash",
    "gemini-1.5-flash-latest",
    "gemini-1.5-flash",
  ];

  static bool get isConfigured => _apiKey.trim().isNotEmpty;

  static GenerativeModel _model(String modelName) {
    return GenerativeModel(
      model: modelName,
      apiKey: _apiKey,
    );
  }

  static Future<String> _generateWithFallback(String prompt) async {
    Object? lastError;
    for (final modelName in _modelCandidates) {
      try {
        final result = await _model(modelName).generateContent([Content.text(prompt)]);
        final text = result.text?.trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      } catch (e) {
        lastError = e;
        final message = e.toString().toLowerCase();
        final modelMissing = message.contains("not found") || message.contains("unsupported");
        if (!modelMissing) rethrow;
      }
    }
    throw Exception(
      "No compatible Gemini model found for this API key/project. Last error: $lastError",
    );
  }

  static Future<String> chatReply({
    required String userPrompt,
    required int todayMinutes,
    required int averageMinutes,
    required int focusScore,
    required int productivityScore,
  }) async {
    if (!isConfigured) {
      return "Gemini API key is missing. Run with --dart-define=GEMINI_API_KEY=your_key.";
    }

    final prompt = """
You are a concise productivity coach inside a Flutter app.
User metrics:
- Today usage minutes: $todayMinutes
- Average daily usage minutes: $averageMinutes
- Focus score (0-100): $focusScore
- Productivity score (0-100): $productivityScore

User question: "$userPrompt"

Rules:
- Keep response under 90 words.
- Give direct practical advice.
- Mention at most one metric in the reply.
""";

    final text = await _generateWithFallback(prompt);
    return text.isNotEmpty ? text : "I could not generate a response right now.";
  }

  static Future<List<String>> generateSuggestions({
    required int todayMinutes,
    required int averageMinutes,
    required int focusScore,
    required int productivityScore,
  }) async {
    if (!isConfigured) {
      return const [
        "Gemini API key is missing. Run with --dart-define=GEMINI_API_KEY=your_key.",
      ];
    }

    final prompt = """
Create exactly 4 short personalized productivity suggestions for this user:
- Today usage minutes: $todayMinutes
- Average daily usage minutes: $averageMinutes
- Focus score (0-100): $focusScore
- Productivity score (0-100): $productivityScore

Output format:
- one suggestion per line
- no numbering
- no markdown
- max 14 words per line
""";

    final raw = await _generateWithFallback(prompt);
    final lines = raw
        .split("\n")
        .map((e) => e.replaceFirst(RegExp(r"^\s*[-*]\s*"), "").trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const ["No AI suggestions generated right now. Please try again."];
    }

    return lines.take(4).toList();
  }
}
