import "package:flutter/material.dart";

/// Shared brand greens and app-wide background gradients.
abstract final class AppColors {
  static const Color green = Color(0xFF22C55E);
  static const Color greenDark = Color(0xFF16A34A);
  static const Color greenAccent = Color(0xFF4ADE80);
  static const Color greenLight = Color(0xFFDCFCE7);
  static const Color greenPale = Color(0xFFECFDF5);
  static const Color beige = Color(0xFFF5F0E6);
  static const Color beigeWarm = Color(0xFFEDE6D6);

  // Dark mode surfaces — soft slate (not pitch black).
  static const Color darkSurface = Color(0xFF1F2630);
  static const Color darkSurfaceElevated = Color(0xFF252E3A);
  static const Color darkSurfaceHigh = Color(0xFF2D3748);
  static const Color darkCard = Color(0xFF2A3340);
  static const Color darkNavBar = Color(0xFF28313D);
  static const Color darkOnSurface = Color(0xFFE8EDF3);
  static const Color darkOnSurfaceVariant = Color(0xFFA8B4C4);

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

  /// Elevated charcoal with a subtle green tint (readable, not flat black).
  static const LinearGradient backgroundGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2C3542),
      Color(0xFF28313D),
      Color(0xFF243029),
      Color(0xFF1F2832),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );

  static LinearGradient backgroundGradientFor(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundGradientDark : backgroundGradient;
}

/// Full-screen gradient behind tab content; follows system theme.
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradientFor(brightness),
      ),
      child: child,
    );
  }
}
