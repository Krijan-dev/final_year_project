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

  /// Prefer [ThemeData.colorScheme.brightness]; also treats low-luminance surfaces as dark.
  static bool isDarkTheme(ThemeData theme) {
    if (theme.colorScheme.brightness == Brightness.dark) return true;
    return theme.colorScheme.surface.computeLuminance() < 0.25;
  }

  static Brightness themeBrightness(ThemeData theme) =>
      isDarkTheme(theme) ? Brightness.dark : Brightness.light;

  /// Amber insight / tip cards (Quick insights on dashboard).
  static ({Color background, Color border, Color icon, Color text}) insightAmber(
    Brightness brightness,
  ) {
    if (brightness == Brightness.dark) {
      return (
        background: const Color(0xFF3A3224),
        border: const Color(0xFF92702A),
        icon: const Color(0xFFFBBF24),
        text: const Color(0xFFFEF3C7),
      );
    }
    return (
      background: const Color(0xFFFFFBEB),
      border: const Color(0xFFFDE68A),
      icon: const Color(0xFFD97706),
      text: const Color(0xFF422006),
    );
  }

  /// Maps light recommendation tints to readable dark-mode surfaces.
  static ({Color background, Color border, Color text, Color subtitle}) tintedCard(
    Brightness brightness, {
    required Color lightBackground,
    required Color lightBorder,
  }) {
    if (brightness == Brightness.light) {
      return (
        background: lightBackground,
        border: lightBorder,
        text: const Color(0xFF0F172A),
        subtitle: const Color(0xFF475569),
      );
    }
    // Amber / orange tips
    if (lightBackground == const Color(0xFFFFFBEB)) {
      return (
        background: const Color(0xFF3A3224),
        border: const Color(0xFF92702A),
        text: const Color(0xFFFEF3C7),
        subtitle: const Color(0xFFD6C4A8),
      );
    }
    // Green
    if (lightBackground == const Color(0xFFECFDF5)) {
      return (
        background: const Color(0xFF1F2E26),
        border: const Color(0xFF2D6B4F),
        text: const Color(0xFFD1FAE5),
        subtitle: const Color(0xFFA7C4B5),
      );
    }
    // Blue
    if (lightBackground == const Color(0xFFEFF6FF)) {
      return (
        background: const Color(0xFF1E2A3D),
        border: const Color(0xFF3B5F8C),
        text: const Color(0xFFDBEAFE),
        subtitle: const Color(0xFFA8BDD8),
      );
    }
    // Purple
    if (lightBackground == const Color(0xFFF5F3FF) || lightBackground == const Color(0xFFF3E8FF)) {
      return (
        background: const Color(0xFF2A2438),
        border: const Color(0xFF5B4A7A),
        text: const Color(0xFFEDE9FE),
        subtitle: const Color(0xFFB8AECC),
      );
    }
    if (lightBackground == const Color(0xFFDCFCE7)) {
      return (
        background: const Color(0xFF1F2E26),
        border: const Color(0xFF2D6B4F),
        text: const Color(0xFFD1FAE5),
        subtitle: const Color(0xFFA7C4B5),
      );
    }
    if (lightBackground == const Color(0xFFDBEAFE)) {
      return (
        background: const Color(0xFF1E2A3D),
        border: const Color(0xFF3B5F8C),
        text: const Color(0xFFDBEAFE),
        subtitle: const Color(0xFFA8BDD8),
      );
    }
    return (
      background: darkCard,
      border: darkSurfaceHigh,
      text: darkOnSurface,
      subtitle: darkOnSurfaceVariant,
    );
  }

  /// Light habit emoji tile tints → readable dark surfaces.
  static Color habitIconSurface(Brightness brightness, Color lightTint) =>
      brightness == Brightness.light
          ? lightTint
          : tintedFromBackground(brightness, lightTint).background;

  static Color moodBarFill(Brightness brightness) =>
      brightness == Brightness.dark
          ? const Color(0xFF9D4B6A)
          : const Color(0xFFF9A8D4);

  /// Same as [tintedCard] but infers a matching border from the light background.
  static ({Color background, Color border, Color text, Color subtitle}) tintedFromBackground(
    Brightness brightness,
    Color lightBackground,
  ) {
    final border = switch (lightBackground.toARGB32()) {
      0xFFFFFBEB => const Color(0xFFFDE68A),
      0xFFECFDF5 => const Color(0xFFBBF7D0),
      0xFFDCFCE7 => const Color(0xFFBBF7D0),
      0xFFEFF6FF => const Color(0xFFBFDBFE),
      0xFFF5F3FF => const Color(0xFFDDD6FE),
      0xFFF3E8FF => const Color(0xFFE8D5FF),
      0xFFDBEAFE => const Color(0xFFBFDBFE),
      _ => const Color(0xFFE2E8F0),
    };
    return tintedCard(
      brightness,
      lightBackground: lightBackground,
      lightBorder: border,
    );
  }

  static ({
    Color background,
    Color foreground,
    Color track,
    Color border,
  }) scoreProductivity(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return (
        background: darkCard,
        foreground: greenAccent,
        track: const Color(0xFF3D4A5C),
        border: const Color(0xFF2D6B4F),
      );
    }
    return (
      background: const Color(0xFFECFDF5),
      foreground: greenDark,
      track: greenDark.withValues(alpha: 0.18),
      border: const Color(0xFFBBF7D0),
    );
  }

  static ({
    Color background,
    Color foreground,
    Color track,
    Color border,
  }) scoreFocus(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return (
        background: darkCard,
        foreground: const Color(0xFFC4B5FD),
        track: const Color(0xFF3D4A5C),
        border: const Color(0xFF5B4A7A),
      );
    }
    return (
      background: const Color(0xFFF5F3FF),
      foreground: const Color(0xFF7C3AED),
      track: const Color(0xFF7C3AED).withValues(alpha: 0.18),
      border: const Color(0xFFDDD6FE),
    );
  }

  static ({
    LinearGradient gradient,
    Color border,
    Color value,
    Color subtitle,
  }) habitCompletionBanner(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return (
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkCard, Color(0xFF243829)],
        ),
        border: const Color(0xFF2D6B4F),
        value: greenAccent,
        subtitle: darkOnSurfaceVariant,
      );
    }
    return (
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
      ),
      border: const Color(0xFF86EFAC),
      value: greenDark,
      subtitle: const Color(0xFF475569),
    );
  }

  static ({
    LinearGradient gradient,
    Color border,
    Color title,
    Color body,
    Color step,
  }) welcomeStarterCard(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return (
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3140), Color(0xFF243829)],
        ),
        border: const Color(0xFF2D6B4F),
        title: const Color(0xFFD1FAE5),
        body: darkOnSurfaceVariant,
        step: greenAccent,
      );
    }
    return (
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          beige.withValues(alpha: 0.95),
          greenPale.withValues(alpha: 0.95),
        ],
      ),
      border: green.withValues(alpha: 0.32),
      title: const Color(0xFF14532D),
      body: const Color(0xFF475569),
      step: const Color(0xFF15803D),
    );
  }

  static ({Color background, Color border}) subtlePanel(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return (background: darkSurfaceHigh, border: darkSurfaceElevated);
    }
    return (
      background: const Color(0xFFF8FAFC),
      border: const Color(0xFFE2E8F0),
    );
  }

  static ({
    Color messageAreaBg,
    Color assistantCard,
    Color assistantBorder,
    Color assistantText,
    Color supportBubbleBg,
    Color supportBubbleText,
    Color inputFill,
    Color inputText,
    Color humanBarBg,
    Color humanBarText,
    Color promptBar,
  }) chatSurfaces(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return (
        messageAreaBg: darkSurface,
        assistantCard: darkCard,
        assistantBorder: const Color(0xFF3D4A5C),
        assistantText: darkOnSurface,
        supportBubbleBg: const Color(0xFF1E2A3D),
        supportBubbleText: const Color(0xFFE8EDF3),
        inputFill: darkSurfaceHigh,
        inputText: darkOnSurface,
        humanBarBg: const Color(0xFF1E2A3D),
        humanBarText: const Color(0xFF93C5FD),
        promptBar: darkSurfaceElevated,
      );
    }
    return (
      messageAreaBg: const Color(0xFFF8FAFC),
      assistantCard: Colors.white,
      assistantBorder: const Color(0xFFE2E8F0),
      assistantText: const Color(0xFF0F172A),
      supportBubbleBg: const Color(0xFFEFF6FF),
      supportBubbleText: const Color(0xFF1E3A8A),
      inputFill: const Color(0xFFF3F4F6),
      inputText: const Color(0xFF0F172A),
      humanBarBg: const Color(0xFFEFF6FF),
      humanBarText: const Color(0xFF1E40AF),
      promptBar: const Color(0xFFF8FAFC),
    );
  }

  static Color habitDayIncomplete(Brightness brightness) =>
      brightness == Brightness.dark ? const Color(0xFF3D4A5C) : const Color(0xFFE5E7EB);

  static Color cardSurface(Brightness brightness) =>
      brightness == Brightness.dark ? darkCard : Colors.white;

  /// Hero cards only — deep jade (calmer than bright [green] accent).
  static const Color heroGreenTop = Color(0xFF1A8F7F);
  static const Color heroGreenBottom = Color(0xFF0D5C54);
  static const Color heroGreenShadow = Color(0x4D1A8F7F);

  static const LinearGradient greenHeroGradient = LinearGradient(
    colors: [heroGreenTop, heroGreenBottom],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color greenHeroCaption = Color(0xFFFFFFFF);
  static const Color greenHeroTitle = Color(0xFFFFFFFF);
  static const Color greenHeroBody = Color(0xE6FFFFFF);
  /// Large score in the corner — visible but secondary to the headline.
  static const Color greenHeroScore = Color(0xBFFFFFFF);

  static BoxDecoration greenHeroInnerTile() => BoxDecoration(
        color: const Color(0x40000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x99FFFFFF), width: 1),
      );

  static TextStyle greenHeroTileLabel() => const TextStyle(
        color: Color(0xFFFFFFFF),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle greenHeroTileValue({bool warning = false}) => TextStyle(
        color: warning ? const Color(0xFFFFF7D6) : const Color(0xFFFFFFFF),
        fontSize: 13,
        fontWeight: FontWeight.w800,
        height: 1.2,
        shadows: warning
            ? const [
                Shadow(color: Color(0xFF422006), offset: Offset(0, 1), blurRadius: 3),
              ]
            : null,
      );

  static BoxDecoration greenHeroChip() => BoxDecoration(
        color: const Color(0x38FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x66FFFFFF)),
      );
}

/// Full-screen gradient behind tab content; follows system theme.
class AppGradientBackground extends StatelessWidget {
  const AppGradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brightness = AppColors.themeBrightness(Theme.of(context));
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradientFor(brightness),
      ),
      child: child,
    );
  }
}
