import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/providers/habit_tracker_provider.dart";
import "package:life_pattern_tracker/providers/theme_provider.dart";
import "package:life_pattern_tracker/providers/usage_provider.dart";
import "package:life_pattern_tracker/screens/health_screen.dart";
import "package:life_pattern_tracker/screens/screen_time_screen.dart";
import "package:life_pattern_tracker/services/api_config.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";
import "package:life_pattern_tracker/services/cloud_sync_service.dart";
import "package:life_pattern_tracker/utils/crisis_support.dart";
import "package:life_pattern_tracker/widgets/subpage_scaffold.dart";

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  static String _initials(String? email) {
    if (email == null || email.isEmpty) return "?";
    final local = email.split("@").first;
    if (local.isEmpty) return "?";
    return local.substring(0, 1).toUpperCase();
  }

  static void _openSubpage(BuildContext context, {required String title, required Widget child}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubpageScaffold(title: title, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final usage = ref.watch(usageProvider);
    final email = auth.email;
    final themeMode = ref.watch(themeModeProvider);
    final signedIn = AuthTokenStore.read().isNotEmpty;
    final apiReady = ApiConfig.isConfigured;
    final cloudAuth = AuthRemoteService.isConfigured;

    Future<void> restoreAllFromCloud({bool showResultSnack = false}) async {
      final ok = await CloudSyncService.restoreFromCloud(includeUsage: true);
      await ref.read(usageProvider.notifier).reloadFromStorage();
      await ref.read(habitTrackerProvider.notifier).refresh();
      if (ref.read(usageProvider).hasPermission) {
        await ref.read(usageProvider.notifier).refreshToday();
      } else {
        await CloudSyncService.pushAll();
      }
      if (showResultSnack && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? "Your data was restored from the cloud."
                  : "Restore finished. No cloud backup found, or you are offline.",
            ),
          ),
        );
      }
    }

    Future<void> confirmRestoreAllFromCloud() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Restore all data from cloud?"),
          content: const Text(
            "Downloads your saved screen time and habits to this device. "
            "Use on a new phone or if local data looks wrong.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Restore"),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await restoreAllFromCloud(showResultSnack: true);
    }

    Future<void> backupToCloud() async {
      await CloudSyncService.pushAll();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Backup sent to your account.")),
      );
    }

    Future<void> confirmSendResetPasswordEmail() async {
      final accountEmail = email?.trim();
      if (accountEmail == null || accountEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No email on this account.")),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Send password reset email?"),
          content: Text(
            "We will email a 6-digit reset code to:\n\n$accountEmail\n\n"
            "Check your inbox and spam. You can enter the code right after to set a new password.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Send email"),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      final result = await ref.read(authProvider.notifier).sendForgotPasswordCodeWithDev(
            accountEmail,
          );

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!context.mounted) return;

      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error!)),
        );
        return;
      }

      if (result.devCode != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Dev mode: your reset code is ${result.devCode}")),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Reset code sent to $accountEmail.")),
        );
      }

      if (!context.mounted) return;
      await showSetNewPasswordDialog(context, ref, accountEmail);
    }

    void showCrisisHelp() {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Crisis support"),
          content: SingleChildScrollView(
            child: Text(CrisisSupport.reply, style: theme.textTheme.bodyMedium),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

    void showLiveSupportHint() {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Live support"),
          content: const Text(
            "Close Account and tap the green chat button at the bottom-right of any tab. "
            "You can talk to the AI assistant or connect with a real person when signed in.",
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Got it"),
            ),
          ],
        ),
      );
    }

    Future<void> showDeleteAccountDialog() async {
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
                      "Permanently deletes your account and synced data. This cannot be undone.",
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
                      onSubmitted: (_) => Navigator.pop(ctx, true),
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
                      if (controller.text.trim().isEmpty) {
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
        final err = await ref
            .read(authProvider.notifier)
            .deleteAccount(password: controller.text.trim());
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _ProfileCard(email: email, initials: _initials(email)),
        const SizedBox(height: 16),
        if (signedIn && cloudAuth) ...[
          _SectionCard(
            title: "Account & security",
            children: [
              _AccountMenuTile(
                icon: Icons.lock_reset_outlined,
                title: "Reset password",
                subtitle: "Send a reset code to your email",
                onTap: confirmSendResetPasswordEmail,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _SectionCard(
          title: "Permissions & data sources",
          children: [
            _AccountMenuTile(
              icon: Icons.phonelink_setup_outlined,
              title: "Usage access",
              subtitle: usage.hasPermission
                  ? "Granted — screen time is tracked"
                  : "Required — open Android settings to enable",
              trailingLabel: usage.hasPermission ? "On" : "Off",
              trailingOk: usage.hasPermission,
              onTap: () => ref.read(usageProvider.notifier).openUsageSettings(),
            ),
            if (!usage.hasPermission)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton(
                  onPressed: () async {
                    await ref.read(usageProvider.notifier).checkPermission();
                  },
                  child: const Text("I granted permission — check again"),
                ),
              ),
            _AccountMenuTile(
              icon: Icons.monitor_heart_outlined,
              title: "Health Connect",
              subtitle: "Steps, sleep, and wellness metrics",
              onTap: () => _openSubpage(
                context,
                title: "Health",
                child: const HealthScreen(embeddedInSubpage: true),
              ),
            ),
            _AccountMenuTile(
              icon: Icons.hourglass_bottom_outlined,
              title: "Screen time & app limits",
              subtitle: "Daily usage, charts, and per-app limits",
              onTap: () => _openSubpage(
                context,
                title: "Screen time",
                child: const ScreenTimeScreen(),
              ),
            ),
          ],
        ),
        if (signedIn && cloudAuth) ...[
          const SizedBox(height: 16),
          _SectionCard(
            title: "Cloud backup",
            children: [
              _AccountMenuTile(
                icon: Icons.cloud_upload_outlined,
                title: "Back up to cloud now",
                subtitle: "Upload usage and habits from this device",
                onTap: backupToCloud,
              ),
              _AccountMenuTile(
                icon: Icons.cloud_download_outlined,
                title: "Restore all data from cloud",
                subtitle: "Download saved usage and habits to this device",
                onTap: confirmRestoreAllFromCloud,
              ),
            ],
          ),
        ] else if (!signedIn && cloudAuth) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Sign in to back up and restore your data across devices.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
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
          title: "Help & support",
          children: [
            _AccountMenuTile(
              icon: Icons.support_agent_outlined,
              title: "Live support chat",
              subtitle: "AI assistant or a real person (when signed in)",
              onTap: showLiveSupportHint,
            ),
            _AccountMenuTile(
              icon: Icons.health_and_safety_outlined,
              title: "Crisis support",
              subtitle: "Lifeline 13 11 14 · Emergency 000",
              iconColor: theme.colorScheme.error,
              onTap: showCrisisHelp,
            ),
          ],
        ),
        const SizedBox(height: 24),
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
              if (confirm != true) return;
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out.")),
              );
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
        if (apiReady && auth.isSignedIn) ...[
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
            title: Text(
              "Delete account",
              style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
            onTap: showDeleteAccountDialog,
          ),
        ],
      ],
    );
  }
}

Future<void> showSetNewPasswordDialog(
  BuildContext context,
  WidgetRef ref,
  String accountEmail,
) async {
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var busy = false;
  var obscure = true;

  try {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submit() async {
              if (!(formKey.currentState?.validate() ?? false)) return;
              setDialogState(() => busy = true);
              final verify = await ref.read(authProvider.notifier).verifyResetCode(
                    accountEmail,
                    codeController.text,
                  );
              if (verify.error != null) {
                setDialogState(() => busy = false);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(verify.error!)),
                  );
                }
                return;
              }
              final err = await ref.read(authProvider.notifier).resetPasswordAndSignIn(
                    accountEmail,
                    passwordController.text,
                    resetToken: verify.resetToken!,
                  );
              if (!ctx.mounted) return;
              if (err != null) {
                setDialogState(() => busy = false);
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(err)));
                return;
              }
              Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password updated.")),
                );
              }
            }

            return AlertDialog(
              title: const Text("Set new password"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Enter the 6-digit code from your email, then choose a new password.",
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: "Reset code",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if ((v?.trim().length ?? 0) != 6) {
                            return "Enter the 6-digit code";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscure,
                        enabled: !busy,
                        decoration: InputDecoration(
                          labelText: "New password",
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: busy
                                ? null
                                : () => setDialogState(() => obscure = !obscure),
                          ),
                        ),
                        validator: (v) {
                          if ((v?.length ?? 0) < 6) {
                            return "At least 6 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmController,
                        obscureText: obscure,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: "Confirm password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v != passwordController.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: busy ? null : () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Update password"),
                ),
              ],
            );
          },
        );
      },
    );
  } finally {
    codeController.dispose();
    passwordController.dispose();
    confirmController.dispose();
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initials,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email ?? "Unknown",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "Signed in",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _AccountMenuTile extends StatelessWidget {
  const _AccountMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.trailingLabel,
    this.trailingOk,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? trailingLabel;
  final bool? trailingOk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = trailingOk == true
        ? theme.colorScheme.primary
        : trailingOk == false
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
      title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: trailingLabel != null
          ? Text(
              trailingLabel!,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
