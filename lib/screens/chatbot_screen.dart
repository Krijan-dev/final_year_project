import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text: "Hi! I am your productivity assistant. Ask me about your usage or focus tips.",
      isUser: false,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                      hintText: "Ask a question...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final state = ref.read(usageProvider);
    final notifier = ref.read(usageProvider.notifier);
    final response = _botReply(
      text: text,
      dailyMinutes: state.today?.totalScreenTime ?? 0,
      averageMinutes: notifier.averageDailyMinutes(),
      focusScore: notifier.focusScore(),
      productivityScore: notifier.productivityScore(),
    );

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(_ChatMessage(text: response, isUser: false));
    });
    _controller.clear();
  }

  String _botReply({
    required String text,
    required int dailyMinutes,
    required int averageMinutes,
    required int focusScore,
    required int productivityScore,
  }) {
    final q = text.toLowerCase();
    if (q.contains("focus")) {
      return "Your focus score is $focusScore/100. Try a 25-minute deep work block, then a 5-minute break.";
    }
    if (q.contains("product") || q.contains("score")) {
      return "Your productivity score is $productivityScore/100. Reducing entertainment app usage can improve it.";
    }
    if (q.contains("today") || q.contains("usage") || q.contains("screen")) {
      return "Today you used ${formatMinutes(dailyMinutes)}. Your average is ${formatMinutes(averageMinutes)}.";
    }
    return "I can help with screen time, focus, and productivity tips. Try asking: 'How can I improve focus?'";
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}
