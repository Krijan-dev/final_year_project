import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";

/// Reset password via email code (cloud API only).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _busy = false;
  int _step = 0;
  String? _resetToken;
  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.trim().isNotEmpty) {
      _email.text = widget.initialEmail!.trim();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!AuthRemoteService.isConfigured) {
      _snack("Password reset requires the cloud API (API_BASE_URL).");
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(authProvider.notifier).sendForgotPasswordCodeWithDev(
          _email.text,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.error == null) {
        _codeSent = true;
        _step = 1;
      }
    });
    if (result.error != null) {
      _snack(result.error!);
      return;
    }
    var msg = "If an account exists, we sent a reset code. Check inbox and spam.";
    if (result.devCode != null) {
      msg = "Dev mode: your code is ${result.devCode}";
    }
    _snack(msg);
  }

  Future<void> _verifyCode() async {
    final code = _code.text.trim();
    if (code.length != 6) {
      _snack("Enter the 6-digit code from your email.");
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(authProvider.notifier).verifyResetCode(
          _email.text,
          code,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result.error == null) {
        _resetToken = result.resetToken;
        _step = 2;
      }
    });
    if (result.error != null) {
      _snack(result.error!);
    }
  }

  Future<void> _setNewPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final token = _resetToken?.trim() ?? "";
    if (token.isEmpty) {
      _snack("Verify the code first.");
      return;
    }
    setState(() => _busy = true);
    final err = await ref.read(authProvider.notifier).resetPasswordAndSignIn(
          _email.text,
          _password.text,
          resetToken: token,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      _snack(err);
      return;
    }
    _snack("Password updated. You are signed in.");
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    const stepLabels = ["Email", "Code", "New password"];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Reset password"),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < stepLabels.length; i++) ...[
                              if (i > 0)
                                Expanded(
                                  child: Container(
                                    height: 2,
                                    color: i <= _step
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outlineVariant,
                                  ),
                                ),
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: i <= _step
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Text(
                                  "${i + 1}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: i <= _step
                                        ? Theme.of(context).colorScheme.onPrimary
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stepLabels[_step.clamp(0, 2)],
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 16),
                        if (_step == 0) ...[
                          TextFormField(
                            controller: _email,
                            enabled: !_codeSent,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: "Account email",
                              border: OutlineInputBorder(),
                              helperText: "We will email a 6-digit reset code if this account exists",
                            ),
                            validator: (v) {
                              if (!AuthNotifier.isValidEmail(v?.trim() ?? "")) {
                                return "Enter a valid email";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _sendCode,
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(_codeSent ? "Resend code" : "Send reset code"),
                          ),
                        ],
                        if (_step == 1) ...[
                          Text(
                            "Code sent to ${_email.text.trim()}",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _code,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: "Reset code",
                              border: OutlineInputBorder(),
                              counterText: "",
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _busy ? null : _verifyCode,
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text("Continue"),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _step = 0;
                                      _code.clear();
                                    }),
                            child: const Text("Change email"),
                          ),
                        ],
                        if (_step == 2) ...[
                          TextFormField(
                            controller: _password,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: "New password",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return "At least 6 characters";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirm,
                            obscureText: _obscureConfirm,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: "Confirm password",
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v != _password.text) return "Passwords do not match";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _busy ? null : _setNewPassword,
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text("Update password"),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
