import "package:flutter/material.dart";
import "package:life_pattern_tracker/screens/chatbot_screen.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

/// Floating assistant chat (bottom-right), like typical web/app support widgets.
class FloatingChatOverlay extends StatefulWidget {
  const FloatingChatOverlay({super.key});

  @override
  State<FloatingChatOverlay> createState() => _FloatingChatOverlayState();
}

class _FloatingChatOverlayState extends State<FloatingChatOverlay>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  static const double _fabSize = 58;
  static const double _horizontalInset = 14;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _anim.forward();
    } else {
      _anim.reverse();
    }
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _anim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    // Sit low in the corner, just above the system gesture area.
    final fabBottom = bottomInset + 6;
    final panelBottom = fabBottom + _fabSize + 14;
    final panelWidth = (size.width - _horizontalInset * 2).clamp(300.0, 400.0);
    final panelHeight = (size.height * 0.56).clamp(380.0, 540.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: [
        Positioned(
          right: _horizontalInset,
          bottom: panelBottom,
          child: IgnorePointer(
            ignoring: !_open,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.bottomRight,
                child: _ChatPanel(
                  width: panelWidth,
                  height: panelHeight,
                  onClose: _close,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: _horizontalInset,
          bottom: fabBottom,
          child: _ChatFab(
            open: _open,
            size: _fabSize,
            onPressed: _toggle,
          ),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.width,
    required this.height,
    required this.onClose,
  });

  final double width;
  final double height;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final chat = AppColors.chatSurfaces(AppColors.themeBrightness(Theme.of(context)));
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.greenDark.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: chat.messageAreaBg,
          child: ChatbotScreen(onClose: onClose),
        ),
      ),
    );
  }
}

class _ChatFab extends StatelessWidget {
  const _ChatFab({
    required this.open,
    required this.size,
    required this.onPressed,
  });

  final bool open;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: open ? "Close assistant chat" : "Open assistant chat",
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: open
                    ? [const Color(0xFF64748B), const Color(0xFF475569)]
                    : [AppColors.green, AppColors.greenDark],
              ),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: (open ? Colors.black : AppColors.green)
                      .withValues(alpha: 0.35),
                  blurRadius: open ? 10 : 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween(begin: 0.85, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  open ? Icons.close_rounded : Icons.forum_rounded,
                  key: ValueKey(open),
                  color: Colors.white,
                  size: open ? 26 : 27,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
