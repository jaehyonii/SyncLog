import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/commit.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/recorded_take.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/team_repository.dart';
import '../../util/app_exception.dart';
import '../../util/time_format.dart';
import '../datasources/seed_data.dart';
import '../datasources/team_local_datasource.dart';
import '../datasources/team_remote_datasource.dart';

/// Local-first repository. The on-device store is the source of truth (seeded on
/// first run); when a [remote] is provided it is consulted best-effort and the
/// result is cached locally, so the app keeps working offline either way.
class TeamRepositoryImpl implements TeamRepository {
  final TeamLocalDataSource _local;
  final TeamRemoteDataSource? _remote;
  final DateTime Function() _now;

  List<Team>? _cache;
  String? _userId;

  TeamRepositoryImpl({
    required TeamLocalDataSource local,
    TeamRemoteDataSource? remote,
    DateTime Function()? now,
  })  : _local = local,
        _remote = remote,
        _now = now ?? DateTime.now;

  @override
  void setActiveUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _local.userId = userId; // scope the on-device store to this account
    _cache = null; // drop the previous user's teams so the next fetch reloads
  }

  Future<List<Team>> _ensureLoaded() async {
    if (_cache != null) return _cache!;

    if (_remote != null) {
      try {
        final remoteTeams = await _remote.fetchTeams();
        _cache = remoteTeams;
        await _local.saveTeams(remoteTeams);
        return remoteTeams;
      } catch (_) {
        // Network unavailable — fall through to the local store.
      }
    }

    final stored = _local.loadTeams();
    if (stored != null) {
      _cache = stored;
      return stored;
    }

    // Only the default (pre-login) profile gets the sample seed content. A real
    // signed-in user with nothing stored yet starts empty and builds their own,
    // so accounts never share teams.
    if (_userId != null) {
      _cache = const [];
      return const [];
    }

    final seeded = SeedData.teams(_now());
    _cache = seeded;
    await _local.saveTeams(seeded);
    return seeded;
  }

  Future<void> _persist() async {
    if (_cache != null) await _local.saveTeams(_cache!);
  }

  @override
  Future<List<Team>> fetchTeams() async => List.unmodifiable(await _ensureLoaded());

  @override
  Future<List<Team>> discoverTeams() async {
    // A browse-only catalog of other teams' takes only exists on the server.
    if (_remote == null) return const [];
    return _remote.discoverTeams();
  }

  @override
  Future<Team> fetchTeam(String teamId) async {
    // In remote mode, pull the team's latest state from the server and refresh
    // the cached copy, so the detail screen reflects others' takes/joins. Fall
    // back to the cache when offline (or in local-first mode).
    if (_remote != null) {
      try {
        final fresh = await _remote.fetchTeam(teamId);
        final teams = await _ensureLoaded();
        final i = teams.indexWhere((t) => t.id == teamId);
        _cache = i == -1
            ? [fresh, ...teams]
            : [...teams.sublist(0, i), fresh, ...teams.sublist(i + 1)];
        await _persist();
        return fresh;
      } catch (_) {
        // Network unavailable — fall through to the cached copy below.
      }
    }

    final teams = await _ensureLoaded();
    final t = teams.where((t) => t.id == teamId).firstOrNull;
    if (t == null) throw const AppException.notFound();
    return t;
  }

  @override
  Future<Team> createTeam({
    required String name,
    required String song,
    required int bpm,
    required int memberCount,
    required Person creator,
  }) async {
    final teams = await _ensureLoaded();
    final id = 'team-${_now().microsecondsSinceEpoch}';
    final slots = <Track>[
      for (var i = 0; i < memberCount; i++)
        () {
          final preset = InstrumentPreset.lineup[i % InstrumentPreset.lineup.length];
          return Track(
            id: '$id-track-$i',
            part: preset.part,
            partKo: preset.partKo,
            instrument: preset.glyph,
            status: TrackStatus.open,
          );
        }(),
    ];

    final team = Team(
      id: id,
      name: name.trim().isEmpty ? '새 합주 팀' : name.trim(),
      song: song.trim().isEmpty ? '곡 미정' : song.trim(),
      artist: '',
      bpm: bpm,
      members: [creator],
      coverColor: _coverFor(teams.length),
      tracks: slots,
      timeline: [
        Commit(
          id: '$id-c0',
          member: creator,
          version: 'v0.1',
          note: song.trim().isEmpty ? '합주 팀 개설' : '합주 팀 개설 · 곡 정함',
          createdAt: _now(),
        ),
      ],
    );

    _cache = [team, ...teams];
    await _persist();
    if (_remote != null) {
      try {
        await _remote.createTeam(team);
      } catch (_) {/* queued locally; will reconcile when online */}
    }
    return team;
  }

  @override
  Future<Team> joinTeam(String code) async {
    // Joining another user's team is inherently a server operation; there is no
    // shared roster to join in local-first mode.
    if (_remote == null) {
      throw const AppException('온라인일 때만 초대 코드로 팀에 참여할 수 있어요.');
    }
    final team = await _remote.joinTeam(code.trim());
    final teams = await _ensureLoaded();
    // Surface the joined team at the top, de-duplicating if already present.
    _cache = [team, ...teams.where((t) => t.id != team.id)];
    await _persist();
    return team;
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
    final teams = await _ensureLoaded();
    final ti = teams.indexWhere((t) => t.id == teamId);
    if (ti == -1) throw const AppException.notFound();
    final team = teams[ti];

    final tracks = [...team.tracks];
    final tr = tracks.indexWhere((t) => t.id == trackId);
    if (tr == -1) throw const AppException.notFound();

    tracks[tr] = tracks[tr].copyWith(
      status: TrackStatus.ready,
      member: member,
      syncOffsetMs: syncOffsetMs,
      localPath: take.filePath,
      note: note?.trim().isNotEmpty == true ? note!.trim() : '${tracks[tr].partKo} 파트 추가',
    );

    final members = team.members.any((m) => m.id == member.id)
        ? team.members
        : [...team.members, member];

    final version = nextVersion(team.latestVersion);
    final commit = Commit(
      id: '$teamId-c-${_now().microsecondsSinceEpoch}',
      member: member,
      version: version,
      note: note?.trim().isNotEmpty == true
          ? note!.trim()
          : '${tracks[tr].partKo} 파트 추가 · 싱크 ${fmtOffset(syncOffsetMs)}',
      part: tracks[tr].part,
      createdAt: _now(),
    );

    final updated = team.copyWith(
      members: members,
      tracks: tracks,
      timeline: [commit, ...team.timeline],
    );

    final next = [...teams];
    next[ti] = updated;
    _cache = next;
    await _persist();

    if (_remote != null) {
      try {
        await _remote.uploadTake(
          teamId: teamId,
          trackId: trackId,
          take: take,
          syncOffsetMs: syncOffsetMs,
          member: member,
          note: note,
        );
      } catch (_) {/* persisted locally; will reconcile when online */}
    }
    return updated;
  }

  static const _covers = [
    Color(0xFFE6DDCF),
    Color(0xFFD8D9D2),
    Color(0xFFDFE2DD),
    Color(0xFFE3DDD2),
    Color(0xFFE0DBD0),
  ];

  Color _coverFor(int index) => _covers[index % _covers.length];
}
