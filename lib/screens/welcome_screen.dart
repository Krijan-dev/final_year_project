import "package:flutter/material.dart";
import "package:life_pattern_tracker/screens/auth_screen.dart";

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width > 900;

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
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(minHeight: 360),
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: isWide
                      ? Row(
                          children: [
                            Expanded(child: _heroText(theme, context)),
                            const SizedBox(width: 24),
                            Expanded(child: _heroImageCard()),
                          ],
                        )
                      : Column(
                          children: [
                            _heroText(theme, context),
                            const SizedBox(height: 16),
                            _heroImageCard(),
                          ],
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: const Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: const [
                      _FeatureCard(
                        title: "Daily Tracking",
                        description: "Measure total screen time and app activity each day.",
                        imageUrl:
                            "https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?auto=format&fit=crop&w=1200&q=80",
                      ),
                      _FeatureCard(
                        title: "Insights",
                        description: "Understand trends and your focus/productivity scores.",
                        imageUrl:
                            "https://images.unsplash.com/photo-1460925895917-afdab827c52f?auto=format&fit=crop&w=1200&q=80",
                      ),
                      _FeatureCard(
                        title: "App Breakdown",
                        description: "See exactly which apps consume the most time.",
                        imageUrl:
                            "https://images.unsplash.com/photo-1611605698335-8b1569810432?auto=format&fit=crop&w=1200&q=80",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Center(
                child: FilledButton.icon(
                  onPressed: () => _openAuth(context),
                  icon: const Icon(Icons.login),
                  label: const Text("Start with your account"),
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

  Widget _heroText(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Understand your digital habits",
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Life Pattern Tracker gives you a clear picture of your screen time, app usage, and focus patterns so you can build healthier routines.",
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip(label: Text("Screen Time")),
            Chip(label: Text("Insights")),
            Chip(label: Text("Focus Score")),
            Chip(label: Text("App Analytics")),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => _openAuth(context),
          icon: const Icon(Icons.account_circle_outlined),
          label: const Text("Log in to see your data"),
        ),
      ],
    );
  }

  Widget _heroImageCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              "https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=1400&q=80",
              fit: BoxFit.cover,
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [Color(0xAA000000), Color(0x00000000)],
                ),
              ),
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                "Track smarter, stay focused, and improve your daily routine.",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  final String title;
  final String description;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
