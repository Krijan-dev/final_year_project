import "package:flutter/material.dart";

/// Shared brand greens and app-wide background gradient (beige → light green).
abstract final class AppColors {
  static const Color green = Color(0xFF22C55E);
  static const Color greenDark = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFDCFCE7);
  static const Color greenPale = Color(0xFFECFDF5);
  static const Color beige = Color(0xFFF5F0E6);
  static const Color beigeWarm = Color(0xFFEDE6D6);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFAF6EE),
      Color(0xFFF0EBE0),
      Color(0xFFE4F3E8),
      Color(0xFFDCFCE7),
      Color(0xFFD1FAE5),
    ],
    stops: [0.0, 0.3, 0.55, 0.8, 1.0],
  );

  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1A1814),
      Color(0xFF1C2119),
      Color(0xFF1A2820),
      Color(0xFF152A22),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );
}

/// Full-screen beige → green gradient behind tab content.
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child, this.dark = false});

  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: dark ? AppColors.backgroundGradientDark : AppColors.backgroundGradient,
      ),
      child: child,
    );
  }
}
