import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:google_generative_ai/google_generative_ai.dart";
import "package:life_pattern_tracker/services/ai_scope.dart";
import "package:life_pattern_tracker/utils/crisis_support.dart";
import "package:life_pattern_tracker/services/gemini_key_store.dart";

class GeminiService {
  GeminiService._();

  static const String _compileTimeApiKey = String.fromEnvironment("GEMINI_API_KEY");

  /// Compile-time defines, bundled `flutter.env`, or debug Hive override.
  static String get resolvedApiKey {
    final fromCompile = _compileTimeApiKey.trim();
    if (fromCompile.isNotEmpty) return fromCompile;
    final fromEnv = dotenv.maybeGet("GEMINI_API_KEY")?.trim() ?? "";
    if (fromEnv.isNotEmpty) return fromEnv;
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

  static GenerativeModel _model(String modelName, {int maxOutputTokens = 180}) {
    return GenerativeModel(
      model: modelName,
      apiKey: resolvedApiKey,
      systemInstruction: Content.system(_coachSystemInstruction),
      generationConfig: GenerationConfig(
        temperature: 0.35,
        maxOutputTokens: maxOutputTokens,
      ),
    );
  }

  static Future<String> _generateWithFallback(
    String prompt, {
    int maxOutputTokens = 180,
  }) async {
    Object? lastError;
    for (final modelName in _modelCandidates) {
      try {
        final result = await _model(modelName, maxOutputTokens: maxOutputTokens)
            .generateContent([Content.text(prompt)]);
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
    required String fullContext,
  }) async {
    if (CrisisSupport.isCrisisRelated(userPrompt)) {
      return CrisisSupport.reply;
    }

    switch (AiScope.classify(userPrompt)) {
      case AiScopeDecision.empty:
        return "Ask me about screen time, habits, sleep, mood, or focus.";
      case AiScopeDecision.greeting:
        return AiScope.greetingReply;
      case AiScopeDecision.help:
        return AiScope.helpReply;
      case AiScopeDecision.offTopic:
        return AiScope.offTopicReply;
      case AiScopeDecision.allowed:
        break;
    }

    if (!isConfigured) {
      return "Gemini API key is missing. Use .\\run_dev.ps1 or "
          "flutter run --dart-define-from-file=.env (then fully stop and start again — hot reload "
          "cannot load new compile-time keys). In debug, use the app bar menu: Paste Gemini key.";
    }

    final prompt = """
You are answering inside Life Pattern Tracker. Use ONLY the user data below.
Give practical, specific advice about habits and/or screen time. Under 90 words.

User data:
$fullContext

User question: "$userPrompt"
""";

    final text = await _generateWithFallback(prompt, maxOutputTokens: 220);
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
Create exactly 4 short personalized health improvement suggestions for this user.
These suggestions should improve wellbeing through sleep, movement, stress, hydration, and healthier phone habits.
Do not use awkward phrasing like "reduce today 26" or "reduce today <number>".
Use natural language with clear actions.
Each line must be a complete suggestion sentence, not a fragment.
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
        .where((e) => !_isBadSuggestionPhrase(e))
        .where(_isCompleteSuggestion)
        .toList();

    if (lines.isEmpty) {
      return const ["No AI suggestions generated right now. Please try again."];
    }

    return lines.take(4).toList();
  }

  static bool _isBadSuggestionPhrase(String value) {
    final text = value.toLowerCase();
    if (text.contains("reduce today")) return true;
    if (RegExp(r"\breduce today\s*\d+\b", caseSensitive: false).hasMatch(value)) return true;
    return false;
  }

  static bool _isCompleteSuggestion(String value) {
    final text = value.trim();
    final words = text.split(RegExp(r"\s+")).where((w) => w.isNotEmpty).toList();
    if (words.length < 6) return false;

    // Reject fragment-like starts such as "Take 15" or "Do 10".
    if (words.length >= 2 &&
        RegExp(r"^\d+$").hasMatch(words[1]) &&
        const {"take", "do", "add", "reduce", "sleep", "walk", "drink"}.contains(words[0].toLowerCase())) {
      return false;
    }

    // Must contain at least one alphabetic token and not end with a raw number.
    if (!RegExp(r"[a-zA-Z]").hasMatch(text)) return false;
    if (RegExp(r"\d+$").hasMatch(text)) return false;

    return true;
  }

  /// Short daily coach blurb for the dashboard (AI).
  static Future<String> generateDashboardInsight({
    required int todayMinutes,
    required int averageMinutes,
    required int focusScore,
    required int productivityScore,
    required int habitCompletionPercent,
    required int bestStreakDays,
    required double? moodAverage,
    required String ruleContext,
  }) async {
    if (!isConfigured) {
      return "Add a Gemini API key to get an AI daily coach summary.";
    }

    final moodLine = moodAverage != null
        ? "Average mood this week: ${moodAverage.toStringAsFixed(1)}/10."
        : "No mood logged this week yet.";

    final prompt = """
Write ONE short dashboard coach paragraph (2-3 sentences, max 55 words) for this user.
Use ONLY the metrics below. Be specific, encouraging, and actionable.
Do not use markdown or bullet points.

Metrics:
- Today screen minutes: $todayMinutes
- Average daily screen minutes: $averageMinutes
- Focus score (0-100): $focusScore
- Productivity score (0-100): $productivityScore
- Habit completion this week (%): $habitCompletionPercent
- Best current habit streak (days): $bestStreakDays
- $moodLine
- Calculated context: $ruleContext
""";

    final text = await _generateWithFallback(prompt);
    return text.isNotEmpty ? text : "Keep tracking habits and screen time to spot patterns.";
  }

  /// AI insight tips for the Insights tab (2–4 items).
  static Future<List<String>> generateInsightTips({
    required String fullContext,
  }) async {
    if (!isConfigured) return [];

    final prompt = """
You are a wellness coach inside a habit and screen-time tracking app.
Read the user's data below and create exactly 3 personalized insights.
Each insight must connect screen time patterns with habits or mood when possible.
Be specific (name apps, hours, or habit names when relevant). Do not invent data not in the context.

Output format — one insight per line:
TITLE|DESCRIPTION
- TITLE: max 6 words
- DESCRIPTION: max 28 words, one actionable sentence
- no numbering, no markdown, no bullets, no extra pipes in TITLE

User data:
$fullContext
""";

    final raw = await _generateWithFallback(
      prompt,
      maxOutputTokens: 420,
    );
    return raw
        .split("\n")
        .map((e) => e.replaceFirst(RegExp(r"^\s*[-*]\s*"), "").trim())
        .where((e) => e.isNotEmpty && e.contains("|"))
        .take(4)
        .toList();
  }
}
