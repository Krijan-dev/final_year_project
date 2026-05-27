import "package:flutter/material.dart";
import "package:life_pattern_tracker/screens/account_screen.dart";
import "package:life_pattern_tracker/screens/health_screen.dart";
import "package:life_pattern_tracker/widgets/subpage_scaffold.dart";

/// Secondary destinations grouped to keep the bottom nav at five items.
class MoreHubScreen extends StatelessWidget {
  const MoreHubScreen({super.key});

  void _open(BuildContext context, {required String title, required Widget screen}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => SubpageScaffold(title: title, child: screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          "More",
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          "Health data, account, sync, and settings.",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _HubTile(
          icon: Icons.monitor_heart_outlined,
          iconColor: const Color(0xFFDC2626),
          title: "Health",
          subtitle: "Steps, sleep, and wellness from Health Connect",
          onTap: () => _open(
            context,
            title: "Health",
            screen: const HealthScreen(embeddedInSubpage: true),
          ),
        ),
        const SizedBox(height: 12),
        _HubTile(
          icon: Icons.person_outline,
          iconColor: const Color(0xFF2563EB),
          title: "Account",
          subtitle: "Sign in, cloud sync, permissions, and dev test data",
          onTap: () => _open(
            context,
            title: "Account",
            screen: const AccountScreen(embeddedInSubpage: true),
          ),
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
