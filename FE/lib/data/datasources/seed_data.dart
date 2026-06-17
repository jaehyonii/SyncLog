import 'package:flutter/material.dart';
import '../../domain/entities/commit.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/team.dart';
import '../../domain/entities/track.dart';

/// First-run seed data — a port of the design kit's demo content, expanded so
/// every team is fully populated (its own tracks + practice timeline). Used to
/// initialize the local store the first time the app runs.
class SeedData {
  SeedData._();

  static const me = Person(id: 'u-me', name: '준호', initial: '준', color: Color(0xFF1A1714));
  static const mina = Person(id: 'u-mina', name: '미나', initial: '미', color: Color(0xFF2F6F8F));
  static const tae = Person(id: 'u-tae', name: '태규', initial: '태', color: Color(0xFFB06A2C));
  static const soo = Person(id: 'u-soo', name: '수민', initial: '수', color: Color(0xFF5B6B3A));
  static const hye = Person(id: 'u-hye', name: '혜원', initial: '혜', color: Color(0xFF8A4A5C));
  static const dan = Person(id: 'u-dan', name: '단', initial: '단', color: Color(0xFF3A5B6B));

  /// Build the seed teams relative to [now] so relative timestamps read well.
  static List<Team> teams(DateTime now) => [
        Team(
          id: 'team-carousel',
          name: '회전목마 합주단',
          song: '인생의 회전목마',
          artist: '히사이시 조',
          bpm: 90,
          members: const [mina, tae, me],
          coverColor: const Color(0xFFE6DDCF),
          tracks: const [
            Track(
              id: 't-carousel-drums',
              part: 'Drums',
              partKo: '드럼',
              instrument: 'drum',
              status: TrackStatus.ready,
              member: tae,
              syncOffsetMs: -40,
              note: '킥을 살짝 당겨서 다시 떴어요',
            ),
            Track(
              id: 't-carousel-bass',
              part: 'Bass',
              partKo: '베이스',
              instrument: 'audio-lines',
              status: TrackStatus.open,
            ),
            Track(
              id: 't-carousel-gtr',
              part: 'Guitar',
              partKo: '기타',
              instrument: 'guitar',
              status: TrackStatus.ready,
              member: mina,
              syncOffsetMs: 20,
              note: '솔로 톤 조금 더 밝게',
            ),
            Track(
              id: 't-carousel-keys',
              part: 'Keys',
              partKo: '건반',
              instrument: 'piano',
              status: TrackStatus.open,
            ),
          ],
          timeline: [
            Commit(id: 'c-carousel-4', member: mina, version: 'v1.2', note: '기타 솔로 다시 떴어요. 톤 밝게 ☀️', part: 'Guitar', createdAt: now.subtract(const Duration(minutes: 1))),
            Commit(id: 'c-carousel-3', member: tae, version: 'v1.1', note: '드럼 킥 타이밍 -0.04s 보정', part: 'Drums', createdAt: now.subtract(const Duration(hours: 2))),
            Commit(id: 'c-carousel-2', member: tae, version: 'v1.0', note: '첫 드럼 트랙 올림. 메트로놈 90', part: 'Drums', createdAt: now.subtract(const Duration(days: 1))),
            Commit(id: 'c-carousel-1', member: mina, version: 'v0.1', note: '합주 팀 개설 · 곡 정함', createdAt: now.subtract(const Duration(days: 2))),
          ],
        ),
        Team(
          id: 'team-citypop',
          name: '야근 시티팝',
          song: 'Plastic Love',
          artist: 'Mariya Takeuchi',
          bpm: 103,
          members: const [soo, hye, dan, me],
          coverColor: const Color(0xFFD8D9D2),
          tracks: const [
            Track(id: 't-citypop-drums', part: 'Drums', partKo: '드럼', instrument: 'drum', status: TrackStatus.ready, member: soo, syncOffsetMs: 0, note: '4비트 셔플로'),
            Track(id: 't-citypop-bass', part: 'Bass', partKo: '베이스', instrument: 'audio-lines', status: TrackStatus.ready, member: hye, syncOffsetMs: 10, note: '슬랩 라인'),
            Track(id: 't-citypop-keys', part: 'Keys', partKo: '건반', instrument: 'piano', status: TrackStatus.ready, member: dan, syncOffsetMs: -10, note: '로즈 톤'),
            Track(id: 't-citypop-gtr', part: 'Guitar', partKo: '기타', instrument: 'guitar', status: TrackStatus.open),
            Track(id: 't-citypop-vox', part: 'Vocal', partKo: '보컬', instrument: 'audio-lines', status: TrackStatus.open),
          ],
          timeline: [
            Commit(id: 'c-citypop-3', member: dan, version: 'v1.4', note: '건반 로즈 톤으로 교체', part: 'Keys', createdAt: now.subtract(const Duration(hours: 5))),
            Commit(id: 'c-citypop-2', member: hye, version: 'v1.2', note: '베이스 슬랩 라인 추가', part: 'Bass', createdAt: now.subtract(const Duration(days: 1, hours: 3))),
            Commit(id: 'c-citypop-1', member: soo, version: 'v1.0', note: '합주 팀 개설 · 드럼 먼저', part: 'Drums', createdAt: now.subtract(const Duration(days: 3))),
          ],
        ),
        Team(
          id: 'team-lofi',
          name: '새벽 로파이',
          song: '비 오는 골목',
          artist: '원곡 · 단',
          bpm: 72,
          members: const [dan, me],
          coverColor: const Color(0xFFDFE2DD),
          tracks: const [
            Track(id: 't-lofi-keys', part: 'Keys', partKo: '건반', instrument: 'piano', status: TrackStatus.ready, member: dan, syncOffsetMs: 0, note: '비 내리는 패드'),
            Track(id: 't-lofi-drums', part: 'Drums', partKo: '드럼', instrument: 'drum', status: TrackStatus.open),
            Track(id: 't-lofi-bass', part: 'Bass', partKo: '베이스', instrument: 'audio-lines', status: TrackStatus.open),
          ],
          timeline: [
            Commit(id: 'c-lofi-2', member: dan, version: 'v1.0', note: '건반 패드 깔았어요', part: 'Keys', createdAt: now.subtract(const Duration(days: 1))),
            Commit(id: 'c-lofi-1', member: dan, version: 'v0.1', note: '합주 팀 개설', createdAt: now.subtract(const Duration(days: 4))),
          ],
        ),
      ];
}
