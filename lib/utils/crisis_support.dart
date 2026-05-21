/// Detects self-harm / suicide crisis language and returns Australian helpline guidance.
abstract final class CrisisSupport {
  static const String reply =
      "I'm really sorry you're going through this. You deserve support, and you don't have to face this alone.\n\n"
      "If you or someone else is in immediate danger, call 000 (Australian emergency services).\n\n"
      "For 24/7 crisis counselling and suicide prevention support, call Lifeline on 13 11 14.\n\n"
      "Please contact one of these services or someone you trust as soon as you can. "
      "This assistant can't replace professional crisis help, but your safety matters.";

  static final List<RegExp> _patterns = [
    RegExp(r"suicid", caseSensitive: false),
    RegExp(r"kill\s+myself", caseSensitive: false),
    RegExp(r"killing\s+myself", caseSensitive: false),
    RegExp(r"end\s+my\s+life", caseSensitive: false),
    RegExp(r"ending\s+my\s+life", caseSensitive: false),
    RegExp(r"take\s+my\s+life", caseSensitive: false),
    RegExp(r"taking\s+my\s+life", caseSensitive: false),
    RegExp(r"want\s+to\s+die", caseSensitive: false),
    RegExp(r"wanna\s+die", caseSensitive: false),
    RegExp(r"wanting\s+to\s+die", caseSensitive: false),
    RegExp(r"trying\s+to\s+die", caseSensitive: false),
    RegExp(r"try\s+to\s+die", caseSensitive: false),
    RegExp(r"commit(ting)?\s+suicide", caseSensitive: false),
    RegExp(r"wish\s+(i\s+)?(was|were)\s+dead", caseSensitive: false),
    RegExp(r"don'?t\s+want\s+to\s+live", caseSensitive: false),
    RegExp(r"do\s+not\s+want\s+to\s+live", caseSensitive: false),
    RegExp(r"better\s+off\s+dead", caseSensitive: false),
    RegExp(r"no\s+reason\s+to\s+live", caseSensitive: false),
    RegExp(r"end\s+it\s+all", caseSensitive: false),
    RegExp(r"want\s+to\s+end\s+it", caseSensitive: false),
    RegExp(r"self[\s-]?harm", caseSensitive: false),
    RegExp(r"hurt(ing)?\s+myself", caseSensitive: false),
    RegExp(r"harm(ing)?\s+myself", caseSensitive: false),
    RegExp(r"cut(ting)?\s+myself", caseSensitive: false),
    RegExp(r"\bunalive\b", caseSensitive: false),
    RegExp(r"not\s+worth\s+living", caseSensitive: false),
    RegExp(r"can'?t\s+go\s+on\s+anymore", caseSensitive: false),
    RegExp(r"cannot\s+go\s+on\s+anymore", caseSensitive: false),
  ];

  static bool isCrisisRelated(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    return _patterns.any((pattern) => pattern.hasMatch(text));
  }
}
