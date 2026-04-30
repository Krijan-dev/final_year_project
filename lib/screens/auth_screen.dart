import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/providers/auth_provider.dart";

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
  final _loginForm = GlobalKey<FormState>();
  final _regForm = GlobalKey<FormState>();
  bool _busy = false;
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
    super.dispose();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 56, color: scheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    "Life Pattern Tracker",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in or create an account to continue.",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tabs,
                    tabs: const [
                      Tab(text: "Log in"),
                      Tab(text: "Sign up"),
                    ],
                  ),
                  const SizedBox(height: 16),
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
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _loginForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _loginEmail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _busy ? null : _submitLogin,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Log in"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _regForm,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _regEmail,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
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
              TextFormField(
                controller: _regPassword,
                obscureText: _obscureReg,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: "Password (min. 6 characters)",
                  border: const OutlineInputBorder(),
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
                  border: const OutlineInputBorder(),
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
              FilledButton(
                onPressed: _busy ? null : _submitRegister,
                child: _busy
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Create account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
