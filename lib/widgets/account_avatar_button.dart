import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/screens/account_screen.dart";
import "package:life_pattern_tracker/widgets/subpage_scaffold.dart";

class AccountAvatarButton extends ConsumerWidget {
  const AccountAvatarButton({super.key});

  static String _initials(String? email) {
    if (email == null || email.isEmpty) return "?";
    final local = email.split("@").first;
    if (local.isEmpty) return "?";
    return local.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final email = ref.watch(authProvider).email;
    final initials = _initials(email);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (ctx) => const SubpageScaffold(
              title: "Account",
              child: AccountScreen(embeddedInSubpage: true),
            ),
          ),
        );
      },
      child: CircleAvatar(
        radius: 18,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.14),
        child: Text(
          initials,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
