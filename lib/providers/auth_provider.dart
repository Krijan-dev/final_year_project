import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_storage_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";

final authStorageServiceProvider = Provider<AuthStorageService>((ref) {
  return AuthStorageService();
});

class AuthState {
  const AuthState({
    this.ready = false,
    this.email,
  });

  final bool ready;
  final String? email;

  bool get isSignedIn => email != null && email!.isNotEmpty;

  AuthState copyWith({
    bool? ready,
    String? email,
    bool clearEmail = false,
  }) {
    return AuthState(
      ready: ready ?? this.ready,
      email: clearEmail ? null : (email ?? this.email),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._storage) : super(const AuthState()) {
    _load();
  }

  final AuthStorageService _storage;

  Future<void> _load() async {
    final email = await _storage.getSessionEmail();
    if (AuthRemoteService.isConfigured) {
      final token = AuthTokenStore.read();
      if (email != null && token.isEmpty) {
        await _storage.logout();
        state = const AuthState(ready: true);
        return;
      }
    }
    state = AuthState(ready: true, email: email);
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) {
    final e = email.trim();
    if (e.length < 5 || !e.contains("@")) return false;
    final parts = e.split("@");
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].contains(".");
  }

  Future<({String? error, String? devCode, String? devHint})> sendVerificationCodeWithDev(
    String email,
  ) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return (error: "Enter a valid email address.", devCode: null, devHint: null);
    }
    if (!AuthRemoteService.isConfigured) {
      return (error: "API not configured.", devCode: null, devHint: null);
    }
    final result = await AuthRemoteService.sendVerificationCode(email: normalized);
    if (!result.ok) {
      return (error: result.error, devCode: null, devHint: null);
    }
    return (error: null, devCode: result.devCode, devHint: result.devHint);
  }

  Future<({String? error, String? verificationToken})> verifyEmailCode(
    String email,
    String code,
  ) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return (error: "Enter a valid email address.", verificationToken: null);
    }
    final result = await AuthRemoteService.verifyEmailCode(
      email: normalized,
      code: code.trim(),
    );
    if (!result.ok) {
      return (error: result.error, verificationToken: null);
    }
    return (error: null, verificationToken: result.verificationToken);
  }

  Future<String?> register(
    String email,
    String password, {
    String? verificationToken,
  }) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return "Enter a valid email address.";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters.";
    }

    if (AuthRemoteService.isConfigured) {
      final token = verificationToken?.trim() ?? "";
      if (token.isEmpty) {
        return "Verify your email with the code we sent first.";
      }
      final result = await AuthRemoteService.register(
        email: normalized,
        password: password,
        verificationToken: token,
      );
      if (!result.ok) return result.error;
      await AuthTokenStore.write(result.token);
      await _storage.setSessionEmail(result.email);
      state = state.copyWith(email: result.email);
      return null;
    }

    final err = await _storage.register(normalized, password);
    if (err == null) {
      state = state.copyWith(email: normalized);
    }
    return err;
  }

  Future<({String? error, String? devCode, String? devHint})> sendForgotPasswordCodeWithDev(
    String email,
  ) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return (error: "Enter a valid email address.", devCode: null, devHint: null);
    }
    if (!AuthRemoteService.isConfigured) {
      return (error: "API not configured.", devCode: null, devHint: null);
    }
    final result = await AuthRemoteService.sendForgotPasswordCode(email: normalized);
    if (!result.ok) {
      return (error: result.error, devCode: null, devHint: null);
    }
    return (error: null, devCode: result.devCode, devHint: result.devHint);
  }

  Future<({String? error, String? resetToken})> verifyResetCode(String email, String code) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return (error: "Enter a valid email address.", resetToken: null);
    }
    final result = await AuthRemoteService.verifyResetCode(
      email: normalized,
      code: code.trim(),
    );
    if (!result.ok) {
      return (error: result.error, resetToken: null);
    }
    return (error: null, resetToken: result.verificationToken);
  }

  Future<String?> resetPasswordAndSignIn(
    String email,
    String password, {
    required String resetToken,
  }) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return "Enter a valid email address.";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters.";
    }
    if (!AuthRemoteService.isConfigured) {
      return "API not configured.";
    }
    final result = await AuthRemoteService.resetPassword(
      email: normalized,
      password: password,
      resetToken: resetToken.trim(),
    );
    if (!result.ok) return result.error;
    await AuthTokenStore.write(result.token);
    await _storage.setSessionEmail(result.email);
    state = state.copyWith(email: result.email);
    return null;
  }

  Future<String?> login(String email, String password) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return "Enter a valid email address.";
    }
    if (password.isEmpty) {
      return "Enter your password.";
    }

    if (AuthRemoteService.isConfigured) {
      final result = await AuthRemoteService.login(
        email: normalized,
        password: password,
      );
      if (!result.ok) return result.error;
      await AuthTokenStore.write(result.token);
      await _storage.setSessionEmail(result.email);
      state = state.copyWith(email: result.email);
      return null;
    }

    final err = await _storage.login(normalized, password);
    if (err == null) {
      state = state.copyWith(email: normalized);
    }
    return err;
  }

  Future<void> logout() async {
    if (AuthRemoteService.isConfigured) {
      final token = AuthTokenStore.read();
      await AuthRemoteService.logout(token: token);
      await AuthTokenStore.write(null);
    }
    await _storage.logout();
    state = state.copyWith(clearEmail: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authStorageServiceProvider));
});
