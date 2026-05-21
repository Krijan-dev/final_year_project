import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/utils/crisis_support.dart";
import "package:life_pattern_tracker/utils/formatters.dart";

const Color _kChatGreen = Color(0xFF22C55E);
const Color _kChatGreenDark = Color(0xFF16A34A);
const Color _kAssistantBubble = Color(0xFFFFFFFF);
const Color _kInputFill = Color(0xFFF3F4F6);

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key, this.onClose});

  /// When set, shows a compact popup header with a close control.
  final VoidCallback? onClose;

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text:
          "Hi! I'm your Life Pattern assistant. Ask about screen time, focus, productivity, or your weekly habits.",
      isUser: false,
    ),
  ];

  static const List<String> _quickPrompts = [
    "How is my focus today?",
    "Today's screen time",
    "Habit progress this week",
    "Tips to reduce usage",
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: base.colorScheme.copyWith(
          primary: _kChatGreen,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFECFDF5),
          surfaceContainerHighest: _kInputFill,
        ),
      ),
      child: Column(
      children: [
        if (widget.onClose != null) _PopupChatHeader(onClose: widget.onClose!),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _messages.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (widget.onClose != null) {
                  return const SizedBox(height: 4);
                }
                return const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _AssistantHeader(),
                );
              }
              final msg = _messages[index - 1];
              return _ChatBubble(message: msg);
            },
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: widget.onClose != null
                ? const Color(0xFFF8FAFC)
                : Colors.transparent,
          ),
          child: _QuickPromptsBar(
            prompts: _quickPrompts,
            onTap: (prompt) {
              _controller.text = prompt;
              _sendMessage();
            },
          ),
        ),
        _ChatInputBar(
          controller: _controller,
          onSend: _sendMessage,
          compact: widget.onClose != null,
        ),
      ],
      ),
    );
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final usage = ref.read(usageProvider);
    final usageNotifier = ref.read(usageProvider.notifier);
    final habitTracker = ref.read(habitTrackerProvider);

    final response = _botReply(
      text: text,
      dailyMinutes: usage.today?.totalScreenTime ?? 0,
      averageMinutes: usageNotifier.averageDailyMinutes(),
      focusScore: usageNotifier.focusScore(),
      productivityScore: usageNotifier.productivityScore(),
      weeklyHabitPercent: habitTracker.weeklyProgressPercent,
      habitTrackerPercent: habitTracker.weeklyProgressPercent,
      moodAverage: habitTracker.averageMood,
      logsToday: habitTracker.todayLogs.length,
    );

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _messages.add(_ChatMessage(text: response, isUser: false));
    });
    _controller.clear();
    _scrollToBottom();
  }

  String _botReply({
    required String text,
    required int dailyMinutes,
    required int averageMinutes,
    required int focusScore,
    required int productivityScore,
    required int weeklyHabitPercent,
    required int habitTrackerPercent,
    required double moodAverage,
    required int logsToday,
  }) {
    if (CrisisSupport.isCrisisRelated(text)) {
      return CrisisSupport.reply;
    }

    final q = text.toLowerCase();

    if (q.contains("habit")) {
      final moodLine = moodAverage > 0
          ? " Average mood this week: ${moodAverage.toStringAsFixed(1)}/10."
          : "";
      return "Your habit completion is $weeklyHabitPercent% this week "
          "($logsToday activity logs today).$moodLine "
          "Open the Habit tab to check off days or log sessions.";
    }
    if (q.contains("focus")) {
      return "Your focus score is $focusScore/100. "
          "Try a 25-minute focus block with notifications off, then take a 5-minute break.";
    }
    if (q.contains("product") || q.contains("score")) {
      return "Your productivity score is $productivityScore/100. "
          "Opening productive apps first each hour can help improve it.";
    }
    if (q.contains("tip") || q.contains("reduce") || q.contains("less")) {
      return "To reduce screen time: set app limits, schedule phone-free meals, "
          "and check Insights for personalized recommendations.";
    }
    if (q.contains("today") || q.contains("usage") || q.contains("screen")) {
      final diff = dailyMinutes - averageMinutes;
      final compare = diff > 0
          ? "${formatMinutes(diff.abs())} above"
          : diff < 0
              ? "${formatMinutes(diff.abs())} below"
              : "in line with";
      return "Today you've used ${formatMinutes(dailyMinutes)} — that's $compare your average "
          "of ${formatMinutes(averageMinutes)}.";
    }
    if (q.contains("hello") || q.contains("hi")) {
      return "Hello! Ask me about focus, screen time, habits, or tips to build healthier routines.";
    }
    return "I can help with screen time, focus scores, habits, and wellness tips. "
        "Try: \"How is my focus today?\" or \"Habit progress this week\".";
  }
}

class _PopupChatHeader extends StatelessWidget {
  const _PopupChatHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kChatGreen, _kChatGreenDark],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Life Pattern Assistant",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Ask about habits & screen time",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantHeader extends StatelessWidget {
  const _AssistantHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _kChatGreen.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _kChatGreen.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.smart_toy_outlined, color: _kChatGreen, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Life Pattern Assistant",
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Powered by your usage & habit data",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
        decoration: BoxDecoration(
          color: isUser ? _kChatGreen : _kAssistantBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? Colors.white : cs.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _QuickPromptsBar extends StatelessWidget {
  const _QuickPromptsBar({
    required this.prompts,
    required this.onTap,
  });

  final List<String> prompts;
  final void Function(String prompt) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              prompts[index],
              style: const TextStyle(fontSize: 12, color: _kChatGreenDark),
            ),
            backgroundColor: const Color(0xFFECFDF5),
            side: const BorderSide(color: Color(0xFFD1FAE5)),
            onPressed: () => onTap(prompts[index]),
          );
        },
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    this.compact = false,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _kChatGreen.withValues(alpha: 0.12)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, compact ? 10 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: compact ? 3 : 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: InputDecoration(
                    hintText: "Message…",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: compact ? 13 : 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: compact ? 10 : 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: _kChatGreen, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                elevation: 2,
                shadowColor: _kChatGreen.withValues(alpha: 0.4),
                color: _kChatGreen,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onSend,
                  borderRadius: BorderRadius.circular(20),
                  splashColor: _kChatGreenDark.withValues(alpha: 0.3),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 10 : 12),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}
