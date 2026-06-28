import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/notification.dart';
import '../../util/app_exception.dart';

/// REST contract for the activity feed, implemented by
/// [HttpNotificationsRemoteDataSource]; swap in a mock for tests.
abstract class NotificationsRemoteDataSource {
  Future<List<AppNotification>> fetch();
  Future<List<AppNotification>> markAllRead();
}

/// Talks to the backend's notification endpoints:
///   GET  /api/v1/notifications        -> Notification[]
///   POST /api/v1/notifications/read   -> Notification[] (all marked read)
///
/// Every route is JWT-protected, so the bearer token (from the auth controller)
/// is attached when present.
class HttpNotificationsRemoteDataSource implements NotificationsRemoteDataSource {
  final String baseUrl;
  final http.Client _client;
  final String? Function()? _tokenProvider;

  HttpNotificationsRemoteDataSource({
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
  Future<List<AppNotification>> fetch() async {
    try {
      final res = await _client.get(_uri('/api/v1/notifications'), headers: _headers());
      _ensureOk(res.statusCode, res.body);
      return _parse(res.body);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e);
    }
  }

  @override
  Future<List<AppNotification>> markAllRead() async {
    try {
      final res = await _client.post(_uri('/api/v1/notifications/read'), headers: _headers());
      _ensureOk(res.statusCode, res.body);
      return _parse(res.body);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e);
    }
  }

  List<AppNotification> _parse(String body) {
    final list = jsonDecode(body) as List;
    return list
        .map((e) => AppNotification.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  void _ensureOk(int status, String body) {
    if (status < 200 || status >= 300) {
      throw AppException('알림을 불러오지 못했어요. ($status)', body);
    }
  }

  void dispose() => _client.close();
}
