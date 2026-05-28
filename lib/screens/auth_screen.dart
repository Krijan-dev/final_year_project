import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";
import "package:life_pattern_tracker/screens/forgot_password_screen.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();
  final _regCode = TextEditingController();
  final _loginForm = GlobalKey<FormState>();
  final _regForm = GlobalKey<FormState>();
  bool _busy = false;
  int _regStep = 0;
  String? _verificationToken;
  bool _codeSent = false;
  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    _regCode.dispose();
    super.dispose();
  }

  void _resetRegisterFlow() {
    setState(() {
      _regStep = 0;
      _verificationToken = null;
      _codeSent = false;
      _regCode.clear();
    });
  }

  Future<void> _submitLogin() async {
    if (!(_loginForm.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final err = await ref.read(authProvider.notifier).login(
          _loginEmail.text,
          _loginPassword.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _sendVerificationCode() async {
    if (!(_regForm.currentState?.validate() ?? false)) return;
    if (!AuthRemoteService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-up requires the cloud API. Set API_BASE_URL in .env.")),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      final result = await ref.read(authProvider.notifier).sendVerificationCodeWithDev(
            _regEmail.text,
          );
      if (!mounted) return;
      if (result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
        return;
      }
      setState(() {
        _codeSent = true;
        _regStep = 1;
      });
      var msg = "Verification code sent. Check your inbox (and spam).";
      if (result.devCode != null) {
        msg = "Dev mode: your code is ${result.devCode}";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _verifyCode() async {
    final code = _regCode.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter the 6-digit code from your email.")),
      );
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(authProvider.notifier).verifyEmailCode(
          _regEmail.text,
          code,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    setState(() {
      _verificationToken = result.verificationToken;
      _regStep = 2;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Email verified. Choose a password.")),
    );
  }

  Future<void> _submitRegister() async {
    if (!(_regForm.currentState?.validate() ?? false)) return;
    if (_regPassword.text != _regConfirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }
    setState(() => _busy = true);
    final err = await ref.read(authProvider.notifier).register(
          _regEmail.text,
          _regPassword.text,
          verificationToken: _verificationToken,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.5),
              scheme.secondaryContainer.withValues(alpha: 0.35),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.95)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [scheme.primary, scheme.secondary],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.lock_outline_rounded, size: 32, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Welcome Back",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Sign in or create an account to continue using Life Pattern Tracker.",
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.98)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabs,
                              onTap: (_) => _resetRegisterFlow(),
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicator: BoxDecoration(
                                color: scheme.primary.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              labelColor: scheme.primary,
                              unselectedLabelColor: scheme.onSurfaceVariant,
                              tabs: const [
                                Tab(text: "Log in"),
                                Tab(text: "Sign up"),
                              ],
                            ),
                            const SizedBox(height: 14),
                            AnimatedBuilder(
                              animation: _tabs,
                              builder: (context, _) {
                                return IndexedStack(
                                  index: _tabs.index,
                                  children: [
                                    _buildLoginCard(context),
                                    _buildRegisterCard(context),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Form(
        key: _loginForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Account login",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _loginEmail,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (v) {
                final e = v?.trim() ?? "";
                if (!AuthNotifier.isValidEmail(e)) {
                  return "Enter a valid email";
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _loginPassword,
              obscureText: _obscureLogin,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_busy) _submitLogin();
              },
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureLogin = !_obscureLogin),
                  icon: Icon(_obscureLogin ? Icons.visibility_off : Icons.visibility),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Enter your password";
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail: _loginEmail.text,
                            ),
                          ),
                        );
                      },
                child: const Text("Forgot password?"),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _submitLogin,
              icon: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_busy ? "Signing in..." : "Log in"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterCard(BuildContext context) {
    final useCloudVerify = AuthRemoteService.isConfigured;
    final stepLabels = ["Email", "Verify", "Password"];

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Form(
        key: _regForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Create account",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
              if (useCloudVerify) ...[
                Row(
                  children: [
                    for (var i = 0; i < stepLabels.length; i++) ...[
                      if (i > 0)
                        Expanded(
                          child: Container(
                            height: 2,
                            color: i <= _regStep
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: i <= _regStep
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Text(
                          "${i + 1}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: i <= _regStep
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
                  stepLabels[_regStep.clamp(0, 2)],
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
              ],
            if (!useCloudVerify || _regStep == 0) ...[
                TextFormField(
                  controller: _regEmail,
                  enabled: !_codeSent || !useCloudVerify,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.mail_outline),
                    helperText: "We will send a 6-digit code to verify this address",
                  ),
                  validator: (v) {
                    final e = v?.trim() ?? "";
                    if (!AuthNotifier.isValidEmail(e)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (useCloudVerify)
                  FilledButton.icon(
                    onPressed: _busy ? null : _sendVerificationCode,
                    icon: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.mark_email_read_outlined),
                    label: Text(_busy
                        ? "Sending..."
                        : (_codeSent ? "Resend code" : "Send verification code")),
                  ),
              ],
              if (useCloudVerify && _regStep == 1) ...[
                Text(
                  "Code sent to ${_regEmail.text.trim()}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _regCode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: "Verification code",
                    prefixIcon: Icon(Icons.verified_outlined),
                    counterText: "",
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy ? null : _verifyCode,
                  icon: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.shield_outlined),
                  label: Text(_busy ? "Verifying..." : "Verify email"),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _regStep = 0;
                            _codeSent = false;
                          }),
                  child: const Text("Change email"),
                ),
              ],
              if (!useCloudVerify || _regStep == 2) ...[
                if (useCloudVerify) ...[
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Email verified",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _regPassword,
                  obscureText: _obscureReg,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: "Password (min. 6 characters)",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscureReg = !_obscureReg),
                      icon: Icon(_obscureReg ? Icons.visibility_off : Icons.visibility),
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
                  controller: _regConfirm,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!_busy) _submitRegister();
                  },
                  decoration: InputDecoration(
                    labelText: "Confirm password",
                    prefixIcon: const Icon(Icons.verified_user_outlined),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                  validator: (v) {
                    if (v != _regPassword.text) return "Does not match password";
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _busy ? null : _submitRegister,
                  icon: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add_alt_1),
                  label: Text(_busy ? "Creating..." : "Create account"),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
