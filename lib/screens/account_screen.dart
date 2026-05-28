import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/dev_spoof_provider.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/theme_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/services/api_config.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/cloud_sync_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/utils/dev_spoof.dart";
import "package:life_pattern_tracker/theme/app_colors.dart";

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key, this.embeddedInSubpage = false});

  /// When opened from More → Account, the app bar already shows the title.
  final bool embeddedInSubpage;

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
    final spoofLevel = ref.watch(devSpoofLevelProvider);

    Future<void> refreshAll() async {
      await CloudSyncService.syncOnSignIn();
      await ref.read(usageProvider.notifier).reloadFromStorage();
      await ref.read(habitTrackerProvider.notifier).refresh();
      if (ref.read(usageProvider).hasPermission) {
        await ref.read(usageProvider.notifier).refreshToday();
      }
    }

    Future<void> showDeleteAccountDialog() async {
      final theme = Theme.of(context);
      final controller = TextEditingController();
      try {
        final confirmed = await showDialog<bool>(
          context: context,
          useRootNavigator: true,
          builder: (ctx) {
            var errorText = "";
            return StatefulBuilder(
              builder: (ctx, setState) => AlertDialog(
                title: const Text("Delete account?"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "This permanently deletes your account and all synced data (usage days, habit snapshots, support chats). This cannot be undone.",
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Confirm password",
                        errorText: errorText.isEmpty ? null : errorText,
                      ),
                      onSubmitted: (_) => Navigator.of(ctx).pop(true),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel"),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    onPressed: () {
                      final pw = controller.text.trim();
                      if (pw.isEmpty) {
                        setState(() => errorText = "Password is required.");
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    child: const Text("Delete"),
                  ),
                ],
              ),
            );
          },
        );
        if (confirmed != true) return;
        final pw = controller.text.trim();
        final err = await ref.read(authProvider.notifier).deleteAccount(password: pw);
        if (!context.mounted) return;
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account deleted.")),
        );
      } finally {
        controller.dispose();
      }
    }

    return RefreshIndicator(
      onRefresh: refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, embeddedInSubpage ? 8 : 20, 16, 24),
        children: [
          if (!embeddedInSubpage) ...[
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
          ],
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
              if (!usage.hasPermission)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "To show screen time & app usage, grant Usage Access permission.",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(usageProvider.notifier).openUsageSettings(),
                        icon: const Icon(Icons.settings),
                        label: const Text("Open Usage Access Settings"),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          await ref.read(usageProvider.notifier).checkPermission();
                        },
                        child: const Text("I granted permission"),
                      ),
                    ],
                  ),
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
                subtitle: const Text("Restore from cloud, then refresh screen time and habits"),
                trailing: usage.syncing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: usage.syncing ? null : refreshAll,
              ),
              const SizedBox(height: 12),
              Text(
                "Test data (spoof)",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<DevSpoofLevel>(
                segments: const [
                  ButtonSegment(
                    value: DevSpoofLevel.off,
                    label: Text("Real data"),
                    icon: Icon(Icons.smart_toy_outlined),
                  ),
                  ButtonSegment(
                    value: DevSpoofLevel.best,
                    label: Text("Best"),
                    icon: Icon(Icons.thumb_up_alt_outlined),
                  ),
                  ButtonSegment(
                    value: DevSpoofLevel.medium,
                    label: Text("Medium"),
                    icon: Icon(Icons.trending_up_outlined),
                  ),
                  ButtonSegment(
                    value: DevSpoofLevel.bad,
                    label: Text("Bad"),
                    icon: Icon(Icons.thumb_down_alt_outlined),
                  ),
                ],
                selected: {spoofLevel},
                onSelectionChanged: (set) {
                  final selected = set.first;
                  DevSpoof.setLevel(selected);
                  ref.read(devSpoofLevelProvider.notifier).state = selected;
                  // Reload providers so the UI updates immediately.
                  ref.read(usageProvider.notifier).checkPermission();
                  ref.read(habitTrackerProvider.notifier).refresh();
                },
              ),
              const SizedBox(height: 8),
              Text(
                "Spoofing updates Dashboard + Habit immediately. Go to Health and pull to refresh if needed.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                  if (!context.mounted) return;
                  Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out.")),
                  );
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
          const SizedBox(height: 12),
          if (apiReady && auth.isSignedIn)
            _SectionCard(
              title: "Danger zone",
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                  title: const Text("Delete account"),
                  subtitle: const Text("Permanently delete your account and synced data"),
                  onTap: showDeleteAccountDialog,
                ),
              ],
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
