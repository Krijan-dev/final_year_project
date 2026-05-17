import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/utils/app_log.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/ai_scope.dart";
import "package:life_pattern_tracker/services/gemini_service.dart";

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: GeminiService.isConfigured
          ? "Hi! I help with habits, screen time, sleep, focus, and productivity using your app data. "
              "Off-topic messages are answered locally (no API call)."
          : "Hi! Add GEMINI_API_KEY with --dart-define to enable AI chat.",
      isUser: false,
    ),
  ];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: GeminiService.isConfigured
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  GeminiService.isConfigured ? "AI: Connected" : "AI: Key missing",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: GeminiService.isConfigured
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _messages.add(const _ChatMessage(text: AiScope.helpReply, isUser: false));
                  });
                },
                child: const Text("Help"),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final align = msg.isUser ? Alignment.centerRight : Alignment.centerLeft;
              final color = msg.isUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest;
              return Align(
                alignment: align,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(msg.text),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: "Screen time, habits, sleep, focus…",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _loading ? null : _sendMessage,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    final scope = AiScope.classify(text);
    if (scope == AiScopeDecision.empty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _controller.clear();

    final localReply = switch (scope) {
      AiScopeDecision.greeting => AiScope.greetingReply,
      AiScopeDecision.help => AiScope.helpReply,
      AiScopeDecision.offTopic => AiScope.offTopicReply,
      AiScopeDecision.empty => null,
      AiScopeDecision.allowed => null,
    };
    if (localReply != null) {
      setState(() => _messages.add(_ChatMessage(text: localReply, isUser: false)));
      return;
    }

    final state = ref.read(usageProvider);
    final notifier = ref.read(usageProvider.notifier);

    setState(() => _loading = true);

    try {
      final response = await GeminiService.chatReply(
        userPrompt: text,
        todayMinutes: state.today?.totalScreenTime ?? 0,
        averageMinutes: notifier.averageDailyMinutes(),
        focusScore: notifier.focusScore(),
        productivityScore: notifier.productivityScore(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
      });
    } catch (e, st) {
      AppLog.e("Gemini chat failed", error: e, stackTrace: st);
      if (!mounted) return;
      final errorText = e.toString();
      final lower = errorText.toLowerCase();
      final isQuotaError = lower.contains("quota") ||
          lower.contains("rate limit") ||
          lower.contains("exceeded your current quota");
      setState(() {
        _messages.add(
          _ChatMessage(
            text: isQuotaError
                ? "Gemini quota exceeded right now. Please enable billing/increase quota, or wait and try again. "
                    "Quick fallback tip: do one 25-minute focus block, then review your top distracting app."
                : "AI error: $errorText",
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}
