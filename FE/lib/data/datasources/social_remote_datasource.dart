import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/ensemble.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/user_profile.dart';
import '../../util/app_exception.dart';

/// Result of a follow/unfollow toggle.
class FollowResult {
  final bool isFollowing;
  final int followerCount;
  const FollowResult({required this.isFollowing, required this.followerCount});

  factory FollowResult.fromJson(Map<String, dynamic> json) => FollowResult(
        isFollowing: json['isFollowing'] as bool? ?? false,
        followerCount: json['followerCount'] as int? ?? 0,
      );
}

/// REST contract for the SNS graph, implemented by [HttpSocialRemoteDataSource].
abstract class SocialRemoteDataSource {
  Future<FollowResult> follow(String userId);
  Future<FollowResult> unfollow(String userId);
  Future<UserProfile> profile(String userId);
  Future<List<Ensemble>> homeFeed();
  Future<List<Ensemble>> explore();
  Future<List<Person>> followers(String userId);
  Future<List<Person>> following(String userId);
}

/// Talks to the backend's social endpoints:
///   POST/DELETE /api/v1/users/:id/follow   -> { isFollowing, followerCount }
///   GET  /api/v1/users/:id                 -> UserProfile
///   GET  /api/v1/users/:id/followers|following -> Person[]
///   GET  /api/v1/feed                      -> Ensemble[] (home feed)
///   GET  /api/v1/ensembles/explore         -> Ensemble[] (explore)
///
/// Every route is JWT-protected, so the bearer token (from the auth controller)
/// is attached when present.
class HttpSocialRemoteDataSource implements SocialRemoteDataSource {
  final String baseUrl;
  final http.Client _client;
  final String? Function()? _tokenProvider;

  HttpSocialRemoteDataSource({
    required this.baseUrl,
    http.Client? client,
    String? Function()? tokenProvider,
  })  : _client = client ?? http.Client(),
        _tokenProvider = tokenProvider;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers() {
    final token = _tokenProvider?.call();
    return {if (token != null) 'Authorization': 'Bearer $token'};
  }

  @override
  Future<FollowResult> follow(String userId) async {
    final body = await _send('POST', '/api/v1/users/$userId/follow');
    return FollowResult.fromJson((jsonDecode(body) as Map).cast<String, dynamic>());
  }

  @override
  Future<FollowResult> unfollow(String userId) async {
    final body = await _send('DELETE', '/api/v1/users/$userId/follow');
    return FollowResult.fromJson((jsonDecode(body) as Map).cast<String, dynamic>());
  }

  @override
  Future<UserProfile> profile(String userId) async {
    final body = await _get('/api/v1/users/$userId');
    return UserProfile.fromJson((jsonDecode(body) as Map).cast<String, dynamic>());
  }

  @override
  Future<List<Ensemble>> homeFeed() async => _ensembles(await _get('/api/v1/feed'));

  @override
  Future<List<Ensemble>> explore() async =>
      _ensembles(await _get('/api/v1/ensembles/explore'));

  @override
  Future<List<Person>> followers(String userId) async =>
      _people(await _get('/api/v1/users/$userId/followers'));

  @override
  Future<List<Person>> following(String userId) async =>
      _people(await _get('/api/v1/users/$userId/following'));

  List<Ensemble> _ensembles(String body) => (jsonDecode(body) as List)
      .map((e) => Ensemble.fromJson((e as Map).cast<String, dynamic>()))
      .toList();

  List<Person> _people(String body) => (jsonDecode(body) as List)
      .map((e) => Person.fromJson((e as Map).cast<String, dynamic>()))
      .toList();

  Future<String> _get(String path) async {
    try {
      final res = await _client.get(_uri(path), headers: _headers());
      _ensureOk(res.statusCode, res.body);
      return res.body;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e);
    }
  }

  Future<String> _send(String method, String path) async {
    try {
      final req = http.Request(method, _uri(path))..headers.addAll(_headers());
      final streamed = await _client.send(req);
      final body = await streamed.stream.bytesToString();
      _ensureOk(streamed.statusCode, body);
      return body;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e);
    }
  }

  void _ensureOk(int status, String body) {
    if (status >= 200 && status < 300) return;
    if (status == 404) throw const AppException.notFound();
    String message = '요청을 처리하지 못했어요. ($status)';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] != null) {
        final m = decoded['message'];
        message = m is List ? m.join('\n') : m.toString();
      }
    } catch (_) {}
    throw AppException.server(status, message, body);
  }

  void dispose() => _client.close();
}
