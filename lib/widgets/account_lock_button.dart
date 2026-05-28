import "package:flutter/material.dart";
import "package:life_pattern_tracker/screens/account_screen.dart";
import "package:life_pattern_tracker/widgets/subpage_scaffold.dart";

class AccountLockButton extends StatelessWidget {
  const AccountLockButton({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SubpageScaffold(
                title: "Account",
                child: AccountScreen(embeddedInSubpage: true),
              ),
            ),
          );
        },
        customBorder: const CircleBorder(),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
            ),
            border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4D1D4ED8),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.lock_outline, color: Colors.white, size: 19),
        ),
      ),
    );
  }
}

