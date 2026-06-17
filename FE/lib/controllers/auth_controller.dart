import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../data/datasources/auth_local_datasource.dart';
import '../data/datasources/auth_remote_datasource.dart';
import '../domain/entities/account.dart';
import '../domain/entities/person.dart';
import '../util/app_exception.dart';

/// Where the app sits in the auth lifecycle. [unknown] only exists before the
/// first [restore]; the router treats it as "wait" so no screen flashes.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// The app's authentication store and single source of truth for "who is
/// signed in". The signed-in [Person] flows out to the rest of the app (home
/// avatar, take attribution) through [currentUser]; the router listens here for
/// redirect gating; the menu drawer calls [logOut].
///
/// Two modes, chosen by whether a [remote] is supplied:
///  - **remote** (a backend is configured): sign-up / log-in hit the API, and
///    the server-issued JWT is cached locally and exposed via [token] so the
///    team data source can send `Authorization: Bearer`.
///  - **local-first** (no backend): accounts live on-device. Passwords are kept
///    only as an FNV-1a digest — deliberately lightweight on-device protection,
///    NOT real security.
class AuthController extends ChangeNotifier {
  final AuthLocalDataSource _store;
  final AuthRemoteDataSource? _remote;

  AuthStatus _status = AuthStatus.unknown;
  Person? _currentUser;
  String? _token;
  bool _busy = false;

  AuthController(this._store, {AuthRemoteDataSource? remote}) : _remote = remote;

  bool get _isRemote => _remote != null;

  AuthStatus get status => _status;
  Person? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// The bearer token in remote mode (null in local mode / when signed out).
  String? get token => _token;

  /// True while a sign-up / log-in request is in flight, so screens can show a
  /// pending state and block double submits.
  bool get busy => _busy;

  /// Restore a persisted session synchronously. Safe to call before the first
  /// frame so the initial route is decided without a logged-out flash.
  void restore() {
    if (_isRemote) {
      final token = _store.token();
      final user = _store.cachedUser();
      if (token != null && user != null) {
        _token = token;
        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    } else {
      final id = _store.currentUserId();
      final account =
          _store.loadAccounts().where((a) => a.id == id).firstOrNull;
      if (account != null) {
        _currentUser = account.toPerson();
        _status = AuthStatus.authenticated;
        notifyListeners();
        return;
      }
    }
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Register and sign in. Throws [AppException] with a user-facing Korean
  /// message on any validation / duplicate-email / network failure.
  Future<Person> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    if (cleanName.isEmpty) throw const AppException('이름을 입력해 주세요.');
    if (!_isValidEmail(cleanEmail)) throw const AppException('올바른 이메일 형식이 아니에요.');
    if (password.length < 6) throw const AppException('비밀번호는 6자 이상이어야 해요.');

    return _guard(() async {
      if (_remote != null) {
        final result = await _remote.signup(
          name: cleanName,
          email: cleanEmail,
          password: password,
        );
        await _activateRemote(result);
        return result.user;
      }

      final accounts = _store.loadAccounts();
      if (accounts.any((a) => a.email == cleanEmail)) {
        throw const AppException('이미 가입된 이메일이에요.');
      }
      final account = Account(
        id: 'u-${_hash(cleanEmail)}',
        name: cleanName,
        email: cleanEmail,
        passwordHash: _hash(password),
      );
      await _store.saveAccounts([...accounts, account]);
      await _activateLocal(account);
      return account.toPerson();
    });
  }

  /// Authenticate. Throws [AppException] on a bad email/password pair, with a
  /// message that does not reveal which was wrong.
  Future<Person> logIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw const AppException('이메일과 비밀번호를 입력해 주세요.');
    }
    return _guard(() async {
      if (_remote != null) {
        final result =
            await _remote.login(email: cleanEmail, password: password);
        await _activateRemote(result);
        return result.user;
      }

      final account = _store
          .loadAccounts()
          .where((a) => a.email == cleanEmail)
          .firstOrNull;
      if (account == null || account.passwordHash != _hash(password)) {
        throw const AppException('이메일 또는 비밀번호가 올바르지 않아요.');
      }
      await _activateLocal(account);
      return account.toPerson();
    });
  }

  Future<void> logOut() async {
    await _store.clearSession();
    _currentUser = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> _activateRemote(AuthResult result) async {
    await _store.saveRemoteSession(result.token, result.user);
    _token = result.token;
    _currentUser = result.user;
    _status = AuthStatus.authenticated;
  }

  Future<void> _activateLocal(Account account) async {
    await _store.setCurrentUserId(account.id);
    _currentUser = account.toPerson();
    _status = AuthStatus.authenticated;
  }

  /// Run an auth operation with the [busy] flag set, always notifying once at
  /// the end so a failed attempt re-enables the form.
  Future<T> _guard<T>(Future<T> Function() op) async {
    _busy = true;
    notifyListeners();
    try {
      return await op();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  static bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  /// Stable non-cryptographic FNV-1a digest (local mode only). Stable across
  /// runs/platforms — unlike `String.hashCode` — so a persisted hash matches.
  static String _hash(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
