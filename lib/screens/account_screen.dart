import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/theme_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/api_config.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static String _initials(String? email) {
    if (email == null || email.isEmpty) return "?";
    final local = email.split("@").first;
    if (local.isEmpty) return "?";
    return local.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final usage = ref.watch(usageProvider);
    final email = auth.email;
    final themeMode = ref.watch(themeModeProvider);
    final hasCloudSession = AuthTokenStore.read().isNotEmpty;
    final apiReady = ApiConfig.isConfigured;

    Future<void> refreshAll() async {
      await Future.wait<void>([
        ref.read(usageProvider.notifier).refreshToday(),
        ref.read(habitTrackerProvider.notifier).refresh(),
      ]);
    }

    return RefreshIndicator(
      onRefresh: refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Text(
            "Account",
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            "Profile, sync, and app settings",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _ProfileCard(email: email, initials: _initials(email)),
          const SizedBox(height: 16),
          _SectionCard(
            title: "Cloud & sync",
            children: [
              _StatusRow(
                icon: Icons.cloud_done_outlined,
                label: "API connection",
                value: apiReady ? "Connected" : "Not configured",
                ok: apiReady,
              ),
              _StatusRow(
                icon: Icons.lock_outline,
                label: "Server session",
                value: hasCloudSession ? "Active" : "Local only",
                ok: hasCloudSession,
              ),
              _StatusRow(
                icon: Icons.sync,
                label: "Usage permission",
                value: usage.hasPermission ? "Granted" : "Not granted",
                ok: usage.hasPermission,
              ),
              if (apiReady && AuthRemoteService.isConfigured)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "Usage, habits, and support chat sync when signed in.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: "Data",
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.refresh, color: theme.colorScheme.primary),
                title: const Text("Refresh all data"),
                subtitle: const Text("Screen time, habits, and dashboard metrics"),
                trailing: usage.syncing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: usage.syncing ? null : refreshAll,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: "Appearance",
            children: [
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text("System")),
                  ButtonSegment(value: ThemeMode.light, label: Text("Light")),
                  ButtonSegment(value: ThemeMode.dark, label: Text("Dark")),
                ],
                selected: {themeMode},
                onSelectionChanged: (set) {
                  ref.read(themeModeProvider.notifier).state = set.first;
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: "Support",
            children: [
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.support_agent_outlined),
                title: Text("Live support"),
                subtitle: Text("Use the chat button on any tab to talk to our team"),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.health_and_safety_outlined, color: theme.colorScheme.error),
                title: const Text("Crisis help"),
                subtitle: const Text("Lifeline 13 11 14 · Emergency 000"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Log out?"),
                    content: Text(
                      email != null
                          ? "Sign out of $email on this device."
                          : "Sign out on this device.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("Cancel"),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("Log out"),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text("Log out"),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Life Pattern Tracker",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.email, required this.initials});

  final String? email;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.green.withValues(alpha: 0.2),
              child: Text(
                initials,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.greenDark,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Signed in as",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email ?? "Unknown",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: ok ? AppColors.greenDark : theme.colorScheme.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: ok ? AppColors.greenDark : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
