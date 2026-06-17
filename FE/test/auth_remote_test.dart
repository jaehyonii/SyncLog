// Remote-auth path: the controller calls the API, caches the JWT + user, and
// restores that session — verified against a mocked HTTP client.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synclog/controllers/auth_controller.dart';
import 'package:synclog/data/datasources/auth_local_datasource.dart';
import 'package:synclog/data/datasources/auth_remote_datasource.dart';

const _userJson = {
  'id': 'u-1',
  'name': '준호',
  'initial': '준',
  'color': 0xFF2F6F8F,
  'email': 'demo@synclog.app',
};

/// A backend stand-in: /signup and /login return a token + user; bad login 401s.
http.Client _fakeApi() {
  // Korean bodies must be UTF-8; http.Response defaults to latin1 without this.
  const utf8Json = {'content-type': 'application/json; charset=utf-8'};
  return MockClient((req) async {
    final path = req.url.path;
    if (path.endsWith('/auth/signup') || path.endsWith('/auth/login')) {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      if (path.endsWith('/login') && body['password'] != 'secret1') {
        return http.Response(
          jsonEncode({'statusCode': 401, 'message': '이메일 또는 비밀번호가 올바르지 않아요.'}),
          401,
          headers: utf8Json,
        );
      }
      return http.Response(
        jsonEncode({'token': 'jwt-abc', 'user': _userJson}),
        201,
        headers: utf8Json,
      );
    }
    return http.Response('not found', 404);
  });
}

AuthRemoteDataSource _remote() =>
    HttpAuthRemoteDataSource(baseUrl: 'http://test', client: _fakeApi());

void main() {
  test('signUp (remote) stores the token and authenticates', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthController(AuthLocalDataSource(prefs), remote: _remote())
      ..restore();

    expect(auth.isAuthenticated, isFalse);

    final user = await auth.signUp(
      name: '준호',
      email: 'demo@synclog.app',
      password: 'secret1',
    );

    expect(auth.isAuthenticated, isTrue);
    expect(auth.token, 'jwt-abc');
    expect(user.id, 'u-1');
    expect(auth.currentUser?.name, '준호');
  });

  test('restore (remote) brings back the cached session', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // First controller signs in and persists the session.
    await AuthController(AuthLocalDataSource(prefs), remote: _remote())
        .logIn(email: 'demo@synclog.app', password: 'secret1');

    // A fresh controller (app restart) restores it synchronously.
    final restored = AuthController(AuthLocalDataSource(prefs), remote: _remote())
      ..restore();

    expect(restored.isAuthenticated, isTrue);
    expect(restored.token, 'jwt-abc');
    expect(restored.currentUser?.email, 'demo@synclog.app');
  });

  test('logIn (remote) surfaces the server error message', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthController(AuthLocalDataSource(prefs), remote: _remote());

    expect(
      () => auth.logIn(email: 'demo@synclog.app', password: 'wrong'),
      throwsA(predicate(
          (e) => e.toString().contains('이메일 또는 비밀번호가 올바르지 않아요'))),
    );
    expect(auth.isAuthenticated, isFalse);
  });

  test('logOut (remote) clears the session', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthController(AuthLocalDataSource(prefs), remote: _remote());
    await auth.signUp(name: '준호', email: 'demo@synclog.app', password: 'secret1');

    await auth.logOut();

    expect(auth.isAuthenticated, isFalse);
    expect(auth.token, isNull);
    // A new controller finds nothing to restore.
    final fresh = AuthController(AuthLocalDataSource(prefs), remote: _remote())
      ..restore();
    expect(fresh.isAuthenticated, isFalse);
  });
}
