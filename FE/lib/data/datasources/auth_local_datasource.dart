import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/person.dart';
import '../../util/app_exception.dart';

/// Persists auth state locally. In **local-first** mode it stores registered
/// accounts plus the active session id (a users table + a session cookie kept
/// on-device). In **remote** mode it instead caches the server-issued bearer
/// token and the signed-in user, so the session survives restarts and can be
/// restored before the first frame (reads are synchronous), avoiding a
/// logged-out flash.
class AuthLocalDataSource {
  static const _accountsKey = 'synclog.auth.accounts.v1';
  static const _sessionKey = 'synclog.auth.session.v1';
  static const _tokenKey = 'synclog.auth.token.v1';
  static const _userKey = 'synclog.auth.user.v1';
  final SharedPreferences _prefs;

  AuthLocalDataSource(this._prefs);

  List<Account> loadAccounts() {
    final raw = _prefs.getString(_accountsKey);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Account.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (e) {
      throw AppException.storage(e);
    }
  }

  Future<void> saveAccounts(List<Account> accounts) async {
    try {
      final raw = jsonEncode(accounts.map((a) => a.toJson()).toList());
      await _prefs.setString(_accountsKey, raw);
    } catch (e) {
      throw AppException.storage(e);
    }
  }

  /// The id of the account whose session is currently active, if any.
  String? currentUserId() => _prefs.getString(_sessionKey);

  Future<void> setCurrentUserId(String id) => _prefs.setString(_sessionKey, id);

  // ---- Remote session (token + cached user) ----

  String? token() => _prefs.getString(_tokenKey);

  Person? cachedUser() {
    final raw = _prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return Person.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRemoteSession(String token, Person user) async {
    await _prefs.setString(_tokenKey, token);
    await _prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Clear every form of active session (local id + remote token/user).
  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }
}
