import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/person.dart';
import '../../util/app_exception.dart';

/// The outcome of a successful sign-up / log-in: the bearer [token] to send on
/// subsequent requests, and the signed-in [user].
class AuthResult {
  final String token;
  final Person user;
  const AuthResult({required this.token, required this.user});
}

/// REST contract for authentication, implemented by [HttpAuthRemoteDataSource].
abstract class AuthRemoteDataSource {
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  });
  Future<AuthResult> login({required String email, required String password});
}

/// Talks to the SyncLog backend's auth endpoints:
///   POST /api/v1/auth/signup  { name, email, password } -> { token, user }
///   POST /api/v1/auth/login   { email, password }       -> { token, user }
///
/// Surfaces the server's own (Korean) error messages so validation/credential
/// failures read the same whether auth is local or remote.
class HttpAuthRemoteDataSource implements AuthRemoteDataSource {
  final String baseUrl;
  final http.Client _client;

  HttpAuthRemoteDataSource({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
  }) =>
      _post('/api/v1/auth/signup', {
        'name': name,
        'email': email,
        'password': password,
      });

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) =>
      _post('/api/v1/auth/login', {'email': email, 'password': password});

  Future<AuthResult> _post(String path, Map<String, dynamic> body) async {
    final http.Response res;
    try {
      res = await _client.post(
        Uri.parse('$baseUrl$path'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
    } catch (e) {
      throw AppException.network(e);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AppException(_messageFrom(res.statusCode, res.body));
    }
    try {
      final json = (jsonDecode(res.body) as Map).cast<String, dynamic>();
      return AuthResult(
        token: json['token'] as String,
        user: Person.fromJson((json['user'] as Map).cast<String, dynamic>()),
      );
    } catch (e) {
      throw AppException('로그인 응답을 처리하지 못했어요.', e);
    }
  }

  /// Pull the user-facing message out of a NestJS error body
  /// (`{ statusCode, message, error }`; `message` may be a string or a list).
  String _messageFrom(int status, String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map && json['message'] != null) {
        final message = json['message'];
        if (message is List && message.isNotEmpty) return message.first.toString();
        return message.toString();
      }
    } catch (_) {/* fall through to a generic message */}
    if (status == 401) return '이메일 또는 비밀번호가 올바르지 않아요.';
    return '요청을 처리하지 못했어요. ($status)';
  }

  void dispose() => _client.close();
}
