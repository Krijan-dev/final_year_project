import "dart:convert";
import "dart:math";

import "package:crypto/crypto.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:life_pattern_tracker/services/auth_remote_service.dart";
import "package:life_pattern_tracker/services/auth_token_store.dart";

class AuthStorageService {
  static const _boxName = "local_auth_box";
  static const _keyUsers = "users";
  static const _keySession = "session_email";

  Future<Box<dynamic>> _openBox() => Hive.openBox<dynamic>(_boxName);

  bool get _useRemoteAuth => AuthRemoteService.isConfigured;

  Future<Map<String, String>> _users() async {
    final box = await _openBox();
    final raw = box.get(_keyUsers);
    if (raw is! Map) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  Future<void> _setUsers(Map<String, String> users) async {
    final box = await _openBox();
    await box.put(_keyUsers, users);
  }

  Future<String?> getSessionEmail() async {
    final box = await _openBox();
    final v = box.get(_keySession);
    if (v is! String || v.isEmpty) return null;
    return v;
  }

  Future<void> setSessionEmail(String? email) async {
    final box = await _openBox();
    if (email == null || email.isEmpty) {
      await box.delete(_keySession);
    } else {
      await box.put(_keySession, email);
    }
  }

  String? get sessionToken => AuthTokenStore.read();

  Future<bool> hasUser(String normalizedEmail) async {
    if (_useRemoteAuth) {
      return true;
    }
    final users = await _users();
    return users.containsKey(normalizedEmail);
  }

  Future<String?> register(String normalizedEmail, String password) async {
    if (_useRemoteAuth) {
      final result = await AuthRemoteService.register(
        email: normalizedEmail,
        password: password,
      );
      if (!result.ok) return result.error;
      await AuthTokenStore.write(result.token);
      await setSessionEmail(result.email);
      return null;
    }

    if (await hasUser(normalizedEmail)) {
      return "An account with this email already exists.";
    }
    final salt = _randomSalt();
    final stored = _hashPassword(password, salt);
    final users = await _users();
    users[normalizedEmail] = stored;
    await _setUsers(users);
    await setSessionEmail(normalizedEmail);
    return null;
  }

  Future<String?> login(String normalizedEmail, String password) async {
    if (_useRemoteAuth) {
      final result = await AuthRemoteService.login(
        email: normalizedEmail,
        password: password,
      );
      if (!result.ok) return result.error;
      await AuthTokenStore.write(result.token);
      await setSessionEmail(result.email);
      return null;
    }

    final users = await _users();
    final stored = users[normalizedEmail];
    if (stored == null) {
      return "No account found for this email.";
    }
    if (!_verifyPassword(password, stored)) {
      return "Incorrect password.";
    }
    await setSessionEmail(normalizedEmail);
    return null;
  }

  Future<void> logout() async {
    if (_useRemoteAuth) {
      final token = AuthTokenStore.read();
      if (token.isNotEmpty) {
        await AuthRemoteService.logout(token: token);
      }
      await AuthTokenStore.write(null);
    }
    await setSessionEmail(null);
  }

  static String _randomSalt() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, "0"))
        .join();
  }

  static String _hashPassword(String password, String salt) {
    final digest = sha256.convert(utf8.encode("$salt$password"));
    return "$salt:${digest.toString()}";
  }

  static bool _verifyPassword(String password, String stored) {
    final parts = stored.split(":");
    if (parts.length != 2) return false;
    final salt = parts[0];
    final expected = parts[1];
    final digest = sha256.convert(utf8.encode("$salt$password"));
    return digest.toString() == expected;
  }
}
