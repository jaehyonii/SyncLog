import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synclog/data/datasources/seed_data.dart';
import 'package:synclog/data/datasources/team_local_datasource.dart';
import 'package:synclog/data/repositories/team_repository_impl.dart';
import 'package:synclog/domain/entities/recorded_take.dart';
import 'package:synclog/domain/entities/track.dart';

void main() {
  // A fixed clock so versions/timestamps are deterministic.
  final clock = DateTime(2026, 6, 17, 12);

  Future<TeamRepositoryImpl> buildRepo() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return TeamRepositoryImpl(
      local: TeamLocalDataSource(prefs),
      now: () => clock,
    );
  }

  test('seeds three teams on first run', () async {
    final repo = await buildRepo();
    final teams = await repo.fetchTeams();
    expect(teams.length, 3);
    expect(teams.first.name, '회전목마 합주단');
  });

  test('createTeam inserts at the top with open slots and a v0.1 commit', () async {
    final repo = await buildRepo();
    final team = await repo.createTeam(
      name: '밤샘 재즈 트리오',
      song: 'Autumn Leaves',
      bpm: 120,
      parts: const [
        (name: '드럼', instrument: 'drum', mine: true),
        (name: '베이스', instrument: 'audio-lines', mine: false),
        (name: '기타', instrument: 'guitar', mine: false),
      ],
      creator: SeedData.me,
    );

    final teams = await repo.fetchTeams();
    expect(teams.first.id, team.id);
    expect(team.tracks.length, 3);
    expect(team.tracks.every((t) => t.status == TrackStatus.open), isTrue);
    expect(team.tracksReady, 0);
    expect(team.bpm, 120);
    expect(team.timeline.single.version, 'v0.1');
    expect(team.members.single.id, SeedData.me.id);
  });

  test('uploadTake fills the slot, bumps the version, and adds a commit', () async {
    final repo = await buildRepo();
    const take = RecordedTake(filePath: null, duration: Duration(seconds: 30), bpm: 90);

    final updated = await repo.uploadTake(
      teamId: 'team-carousel',
      trackId: 't-carousel-bass',
      take: take,
      syncOffsetMs: 20,
      member: SeedData.me,
      note: '베이스 라인 추가',
    );

    final bass = updated.trackById('t-carousel-bass')!;
    expect(bass.status, TrackStatus.ready);
    expect(bass.member!.id, SeedData.me.id);
    expect(bass.syncOffsetMs, 20);
    expect(updated.tracksReady, 3); // was 2

    // Latest seeded version was v1.2 → next is v1.3.
    expect(updated.timeline.first.version, 'v1.3');
    expect(updated.timeline.first.note, '베이스 라인 추가');
    expect(updated.members.any((m) => m.id == SeedData.me.id), isTrue);
  });

  test('persists across repository instances (local-first)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final repo1 = TeamRepositoryImpl(local: TeamLocalDataSource(prefs), now: () => clock);
    await repo1.createTeam(
      name: '지속성 테스트',
      song: '곡',
      bpm: 90,
      parts: const [
        (name: '보컬', instrument: 'audio-lines', mine: true),
        (name: '기타', instrument: 'guitar', mine: false),
      ],
      creator: SeedData.me,
    );

    // A fresh repository over the same storage sees the created team.
    final repo2 = TeamRepositoryImpl(local: TeamLocalDataSource(prefs), now: () => clock);
    final teams = await repo2.fetchTeams();
    expect(teams.any((t) => t.name == '지속성 테스트'), isTrue);
  });

  test('accounts do not share teams (per-user store)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = TeamRepositoryImpl(local: TeamLocalDataSource(prefs), now: () => clock);

    // Alice signs in and creates a team.
    repo.setActiveUser('alice');
    await repo.createTeam(
      name: '앨리스 밴드',
      song: '곡',
      bpm: 90,
      parts: const [
        (name: '보컬', instrument: 'audio-lines', mine: true),
        (name: '기타', instrument: 'guitar', mine: false),
      ],
      creator: SeedData.me,
    );
    expect((await repo.fetchTeams()).any((t) => t.name == '앨리스 밴드'), isTrue);

    // Bob signs in on the same device: he must NOT see Alice's team, and a
    // fresh signed-in account starts empty (no sample seed).
    repo.setActiveUser('bob');
    final bobTeams = await repo.fetchTeams();
    expect(bobTeams.any((t) => t.name == '앨리스 밴드'), isFalse);
    expect(bobTeams, isEmpty);

    // Switching back to Alice restores her team (still scoped to her).
    repo.setActiveUser('alice');
    expect((await repo.fetchTeams()).any((t) => t.name == '앨리스 밴드'), isTrue);
  });

  test('uploadTake throws for an unknown team', () async {
    final repo = await buildRepo();
    const take = RecordedTake(filePath: null, duration: Duration(seconds: 1), bpm: 90);
    expect(
      () => repo.uploadTake(
        teamId: 'nope',
        trackId: 'nope',
        take: take,
        syncOffsetMs: 0,
        member: SeedData.me,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
