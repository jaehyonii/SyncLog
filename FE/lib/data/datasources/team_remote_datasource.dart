import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/person.dart';
import '../../domain/entities/recorded_take.dart';
import '../../domain/entities/team.dart';
import '../../util/app_exception.dart';

/// REST contract for the SyncLog backend (per the product spec). Implemented by
/// [HttpTeamRemoteDataSource]; swap in a mock for tests.
abstract class TeamRemoteDataSource {
  Future<List<Team>> fetchTeams();
  Future<Team> fetchTeam(String teamId);
  Future<Team> createTeam(Team team);
  Future<Team> uploadTake({
    required String teamId,
    required String trackId,
    required RecordedTake take,
    required int syncOffsetMs,
    required Person member,
    String? note,
  });
}

/// Talks to the real REST API described in the spec:
///   GET  /api/v1/teams
///   GET  /api/v1/teams/{id}/stream
///   POST /api/v1/teams
///   POST /api/v1/teams/{id}/record   (multipart: video + sync_offset_ms)
///
/// Wired and ready; the app stays local-first until a live server is configured
/// (see [AppConfig.useRemote]).
class HttpTeamRemoteDataSource implements TeamRemoteDataSource {
  final String baseUrl;
  final http.Client _client;

  HttpTeamRemoteDataSource({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> get _jsonHeaders => const {'Content-Type': 'application/json'};

  @override
  Future<List<Team>> fetchTeams() async {
    final res = await _get('/api/v1/teams');
    final list = jsonDecode(res) as List;
    return list.map((e) => Team.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  @override
  Future<Team> fetchTeam(String teamId) async {
    final res = await _get('/api/v1/teams/$teamId/stream');
    return Team.fromJson((jsonDecode(res) as Map).cast<String, dynamic>());
  }

  @override
  Future<Team> createTeam(Team team) async {
    final res = await _send(http.Request('POST', _uri('/api/v1/teams'))
      ..headers.addAll(_jsonHeaders)
      ..body = jsonEncode(team.toJson()));
    return Team.fromJson((jsonDecode(res) as Map).cast<String, dynamic>());
  }

  @override
  Future<Team> uploadTake({
    required String teamId,
    required String trackId,
    required RecordedTake take,
    required int syncOffsetMs,
    required Person member,
    String? note,
  }) async {
    final req = http.MultipartRequest('POST', _uri('/api/v1/teams/$teamId/record'))
      ..fields['track_id'] = trackId
      ..fields['sync_offset_ms'] = '$syncOffsetMs'
      ..fields['member_id'] = member.id
      ..fields['note'] = note ?? '';
    if (take.filePath != null) {
      req.files.add(await http.MultipartFile.fromPath('video', take.filePath!));
    }
    try {
      final streamed = await _client.send(req);
      final body = await streamed.stream.bytesToString();
      _ensureOk(streamed.statusCode, body);
      return Team.fromJson((jsonDecode(body) as Map).cast<String, dynamic>());
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e);
    }
  }

  Future<String> _get(String path) async {
    try {
      final res = await _client.get(_uri(path));
      _ensureOk(res.statusCode, res.body);
      return res.body;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.network(e);
    }
  }

  Future<String> _send(http.Request request) async {
    try {
      final streamed = await _client.send(request);
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
    if (status == 404) throw const AppException.notFound();
    if (status < 200 || status >= 300) {
      throw AppException('서버 오류가 발생했어요. ($status)', body);
    }
  }

  void dispose() => _client.close();
}
