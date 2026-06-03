import "package:flutter/material.dart";
import "package:life_pattern_tracker/screens/auth_screen.dart";

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final PageController _pageController;
  int _page = 0;

  static const List<_WelcomeFeaturePageData> _pages = [
    _WelcomeFeaturePageData(
      title: "Understand your digital habits",
      description:
          "Track screen time, app usage, and focus trends to build healthier routines every day.",
      icon: Icons.query_stats_rounded,
      bullets: [
        "Live screen-time metrics",
        "Category and app breakdown",
        "Daily focus and productivity score",
      ],
      accent: Color(0xFF16A34A),
    ),
    _WelcomeFeaturePageData(
      title: "Build habits that actually stick",
      description:
          "Set weekly goals, log fast, and keep momentum with streaks and progress visuals.",
      icon: Icons.check_circle_outline_rounded,
      bullets: [
        "Weekly habit planner",
        "One-tap daily logging",
        "Mood and wellness trend view",
      ],
      accent: Color(0xFF0D9488),
    ),
    _WelcomeFeaturePageData(
      title: "Talk with AI and real people",
      description:
          "Get personalized AI suggestions and connect with real human support whenever needed.",
      icon: Icons.support_agent_rounded,
      bullets: [
        "AI coach for habits and screen time",
        "Real support chat with your team",
        "Built-in crisis support information",
      ],
      accent: Color(0xFF2563EB),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.93);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final cardHeight = size.height * 0.62;
    final carouselShellColor = isDark
        ? scheme.surfaceContainerHigh.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.42);
    final carouselShellBorder = scheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.62);
    final ctaCardColor = theme.cardTheme.color ?? scheme.surfaceContainerHigh;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Life Pattern Tracker"),
        actions: [
          TextButton(
            onPressed: () => _openAuth(context),
            child: const Text("Log in"),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: () => _openAuth(context),
              child: const Text("Sign up"),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    decoration: BoxDecoration(
                      color: carouselShellColor,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: carouselShellBorder),
                      boxShadow: isDark
                          ? const <BoxShadow>[]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                    ),
                    child: SizedBox(
                      height: cardHeight.clamp(520.0, 680.0),
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _pages.length,
                        onPageChanged: (index) => setState(() => _page = index),
                        itemBuilder: (context, index) {
                          final data = _pages[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: _WelcomeFeaturePage(
                              data: data,
                              onLoginTap: () => _openAuth(context),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page ? _pages[i].accent : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: ctaCardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.55 : 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Start in under a minute",
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Create your account, grant usage permission, and see your first insight.",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _openAuth(context),
                            icon: const Icon(Icons.rocket_launch_outlined),
                            label: const Text("Get started"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    "Built for healthier routines, not just lower screen time.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _openAuth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AuthScreen(),
      ),
    );
  }
}

class _WelcomeFeaturePageData {
  const _WelcomeFeaturePageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.bullets,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final List<String> bullets;
  final Color accent;
}

class _WelcomeFeaturePage extends StatelessWidget {
  const _WelcomeFeaturePage({
    required this.data,
    required this.onLoginTap,
  });

  final _WelcomeFeaturePageData data;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: data.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: data.accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                "Feature ${(data.icon.codePoint % 3) + 1}",
                style: theme.textTheme.labelMedium?.copyWith(
                  color: data.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: data.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, color: data.accent, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.description,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            ...data.bullets.map(
              (point) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, size: 18, color: data.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        point,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onLoginTap,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text("Log in to see your data"),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.accent.withValues(alpha: 0.22),
                      data.accent.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: data.accent.withValues(alpha: 0.25)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -24,
                      left: -20,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.accent.withValues(alpha: 0.13),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 24,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.accent.withValues(alpha: 0.16),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          data.icon,
                          size: 54,
                          color: data.accent.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.swipe, size: 18, color: data.accent),
                            const SizedBox(width: 8),
                            Text(
                              "Swipe to explore more features",
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Personalized onboarding\nfor your routine",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
