/// Client-side gate so off-topic chat never calls Gemini (saves API tokens).
abstract final class AiScope {
  static const String offTopicReply =
      "I only help with habits, screen time, sleep, mood, focus, and productivity in Life Pattern Tracker. "
      "Try: \"Why is my focus score low?\" or \"How can I cut screen time today?\"";

  static const String greetingReply =
      "Hi! Ask about your screen time, habits, sleep, focus score, or productivity — I'll use your app data when I answer.";

  static const String helpReply =
      "Examples you can ask:\n"
      "• Why is my focus score low?\n"
      "• How can I reduce screen time today?\n"
      "• Tips for better sleep habits\n"
      "• What does my habit completion mean?\n"
      "• Should I set a limit for social apps?\n\n"
      "Off-topic questions are not sent to AI (saves your API quota).";

  static const int maxMessageLength = 400;

  static final RegExp _blocked = RegExp(
    r"\b("
    r"write\s+(an?\s+)?(essay|code|story|poem|script|email|letter)|"
    r"homework|assignment|dissertation|thesis|"
    r"solve\s+this|calculate\s+\d|math\s+problem|"
    r"translate\s+to|translation|"
    r"weather|forecast|"
    r"news|politics|election|president|"
    r"stock|crypto|bitcoin|invest|"
    r"recipe\s+for|cook\s+me|"
    r"who\s+is|when\s+was|capital\s+of|"
    r"joke|riddle|trivia|"
    r"python|javascript|java\s+code|flutter\s+code|debug\s+this|"
    r"medical\s+diagnosis|prescribe|dosage|"
    r"legal\s+advice|lawyer"
    r")\b",
    caseSensitive: false,
  );

  static final RegExp _allowed = RegExp(
    r"\b("
    r"habit|routine|screen\s*time|phone|usage|app|apps|distract|scroll|"
    r"limit|limits|cap|notification|alert|nudge|"
    r"sleep|bed|rest|tired|insomnia|"
    r"step|walk|exercise|workout|fitness|health\s*connect|"
    r"focus|productive|productivity|score|metric|streak|"
    r"mood|stress|anxiety|calm|meditat|"
    r"water|hydrat|break|pomodoro|goal|morning|evening|"
    r"pattern|life\s*pattern|tracker|today|average|minute|hour|daily|weekly|"
    r"reduce|improve|better|less|more|why|how|tip|advice|suggest|help|"
    r"social|tiktok|instagram|youtube|game|games|"
    r"log|logging|check|check-?in|complete|completion|progress|"
    r"wellness|wellbeing|digital|balance"
    r")\b",
    caseSensitive: false,
  );

  /// Coach-style phrasing even when keywords are missing.
  static final RegExp _coachIntent = RegExp(
    r"\b("
    r"my\s+(habit|screen|focus|mood|sleep|usage|time|score|streak|progress)|"
    r"should\s+i|can\s+i|could\s+i|what\s+should|how\s+do\s+i|"
    r"why\s+is|why\s+am|why\s+are|"
    r"too\s+much|too\s+long|cut\s+down|cut\s+back"
    r")\b",
    caseSensitive: false,
  );

  static final RegExp _greetingOnly = RegExp(
    r"^(hi|hello|hey|yo|thanks|thank\s*you|thx|ok|okay|bye|goodbye|good\s*(morning|afternoon|evening)|"
    r"how\s+are\s+you)[\s!.?]*$",
    caseSensitive: false,
  );

  static final RegExp _helpOnly = RegExp(
    r"^(help|\?|what\s+can\s+you\s+do|what\s+do\s+you\s+do)[\s!.?]*$",
    caseSensitive: false,
  );

  static AiScopeDecision classify(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return AiScopeDecision.empty;
    if (text.length > maxMessageLength) return AiScopeDecision.offTopic;
    if (_helpOnly.hasMatch(text)) return AiScopeDecision.help;
    if (_greetingOnly.hasMatch(text)) return AiScopeDecision.greeting;
    if (_blocked.hasMatch(text)) return AiScopeDecision.offTopic;
    if (_allowed.hasMatch(text)) return AiScopeDecision.allowed;
    if (_coachIntent.hasMatch(text)) return AiScopeDecision.allowed;
    return AiScopeDecision.offTopic;
  }

  static bool allowsApiCall(String message) => classify(message) == AiScopeDecision.allowed;
}

enum AiScopeDecision { empty, allowed, offTopic, greeting, help }
