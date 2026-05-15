import "package:google_generative_ai/google_generative_ai.dart";
import "package:life_pattern_tracker/services/ai_scope.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";

class GeminiService {
  GeminiService._();

  static const String _compileTimeApiKey = String.fromEnvironment("GEMINI_API_KEY");

  /// Compile-time (`--dart-define` / `--dart-define-from-file=.env`) or debug Hive override.
  static String get resolvedApiKey {
    final fromCompile = _compileTimeApiKey.trim();
    if (fromCompile.isNotEmpty) return fromCompile;
    return GeminiKeyStore.readDebugOverride();
  }

  static const List<String> _modelCandidates = [
    "gemini-2.5-flash",
    "gemini-1.5-flash-latest",
    "gemini-1.5-flash",
    "gemini-1.5-pro",
  ];

  static bool get isConfigured => resolvedApiKey.isNotEmpty;

  static const String _coachSystemInstruction = """
You are the Life Pattern Tracker assistant — a concise productivity and wellness coach.
You ONLY discuss: habits, routines, screen time, phone usage, sleep, exercise, mood, focus, productivity scores, and goals using the user's app metrics.
If the user asks anything else, reply ONLY with this exact sentence and nothing else:
"${AiScope.offTopicReply}"
Never answer off-topic questions, even briefly. No jokes, code, homework, news, or general knowledge.
Keep replies under 80 words. Mention at most one metric when relevant.
""";

  static GenerativeModel _model(String modelName) {
    return GenerativeModel(
      model: modelName,
      apiKey: resolvedApiKey,
      systemInstruction: Content.system(_coachSystemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.35,
        maxOutputTokens: 180,
      ),
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
        final tryNextModel = message.contains("not found") ||
            message.contains("unsupported") ||
            message.contains("no longer available") ||
            message.contains("not available to new users") ||
            message.contains("deprecated");
        if (!tryNextModel) rethrow;
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
    if (!AiScope.allowsApiCall(userPrompt)) {
      return AiScope.offTopicReply;
    }

    if (!isConfigured) {
      return "Gemini API key is missing. Use .\\run_dev.ps1 or "
          "flutter run --dart-define-from-file=.env (then fully stop and start again — hot reload "
          "cannot load new compile-time keys). In debug, use the app bar menu: Paste Gemini key.";
    }

    final prompt = """
User metrics:
- Today usage minutes: $todayMinutes
- Average daily usage minutes: $averageMinutes
- Focus score (0-100): $focusScore
- Productivity score (0-100): $productivityScore

User question: "$userPrompt"
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
        "Gemini API key is missing. Run with --dart-define-from-file=.env after a full restart, "
        "or paste key via debug menu.",
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
