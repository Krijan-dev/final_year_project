import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/services/auth_storage_service.dart";

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
    state = AuthState(ready: true, email: email);
  }

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) {
    final e = email.trim();
    if (e.length < 5 || !e.contains("@")) return false;
    final parts = e.split("@");
    return parts.length == 2 && parts[0].isNotEmpty && parts[1].contains(".");
  }

  Future<String?> register(String email, String password) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return "Enter a valid email address.";
    }
    if (password.length < 6) {
      return "Password must be at least 6 characters.";
    }
    final err = await _storage.register(normalized, password);
    if (err == null) {
      state = state.copyWith(email: normalized);
    }
    return err;
  }

  Future<String?> login(String email, String password) async {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return "Enter a valid email address.";
    }
    if (password.isEmpty) {
      return "Enter your password.";
    }
    final err = await _storage.login(normalized, password);
    if (err == null) {
      state = state.copyWith(email: normalized);
    }
    return err;
  }

  Future<void> logout() async {
    await _storage.logout();
    state = state.copyWith(clearEmail: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authStorageServiceProvider));
});
