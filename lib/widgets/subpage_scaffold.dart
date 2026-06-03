import "package:flutter/material.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

/// Full-screen shell for routes opened from More (or elsewhere) — matches [HomeShell] look.
class SubpageScaffold extends StatelessWidget {
  const SubpageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: actions,
        ),
        body: SafeArea(
          top: false,
          child: child,
        ),
      ),
    );
  }
}
