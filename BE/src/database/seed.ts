import * as bcrypt from 'bcryptjs';
import { avatarColor, initialOf } from '../common/avatar';
import { CommitEntity } from '../teams/entities/commit.entity';
import { TeamMemberEntity } from '../teams/entities/team-member.entity';
import { TeamEntity } from '../teams/entities/team.entity';
import { TrackEntity } from '../teams/entities/track.entity';
import { UserEntity } from '../users/user.entity';
import { buildDataSource } from './data-source';

/**
 * Seeds a demo account and the three example teams from the client's
 * `FE/lib/data/datasources/seed_data.dart`, so a fresh database has something to
 * show. Idempotent: re-running after the demo user exists is a no-op.
 *
 *   npm run seed      # (with the DB env vars / a running compose db)
 *
 * Demo login —  email: demo@synclog.app   password: synclog1
 */

const PASSWORD = 'synclog1';
const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

interface TrackSpec {
  part: string;
  partKo: string;
  glyph: string;
  member?: string; // people-map key; absent = open slot
  offset?: number;
  note?: string;
}

interface CommitSpec {
  member: string;
  version: string;
  note: string;
  part?: string;
  ago: number; // ms before "now"
}

interface TeamSpec {
  name: string;
  song: string;
  artist: string;
  bpm: number;
  cover: number;
  owner: string;
  members: string[]; // listed in roster order
  tracks: TrackSpec[];
  timeline: CommitSpec[];
}

const PEOPLE: Record<string, { name: string; email: string }> = {
  me: { name: '준호', email: 'demo@synclog.app' },
  mina: { name: '미나', email: 'mina@synclog.app' },
  tae: { name: '태규', email: 'tae@synclog.app' },
  soo: { name: '수민', email: 'soo@synclog.app' },
  hye: { name: '혜원', email: 'hye@synclog.app' },
  dan: { name: '단', email: 'dan@synclog.app' },
};

const TEAMS: TeamSpec[] = [
  {
    name: '회전목마 합주단',
    song: '인생의 회전목마',
    artist: '히사이시 조',
    bpm: 90,
    cover: 0xffe6ddcf,
    owner: 'me',
    members: ['mina', 'tae', 'me'],
    tracks: [
      { part: 'Drums', partKo: '드럼', glyph: 'drum', member: 'tae', offset: -40, note: '킥을 살짝 당겨서 다시 떴어요' },
      { part: 'Bass', partKo: '베이스', glyph: 'audio-lines' },
      { part: 'Guitar', partKo: '기타', glyph: 'guitar', member: 'mina', offset: 20, note: '솔로 톤 조금 더 밝게' },
      { part: 'Keys', partKo: '건반', glyph: 'piano' },
    ],
    timeline: [
      { member: 'mina', version: 'v1.2', note: '기타 솔로 다시 떴어요. 톤 밝게 ☀️', part: 'Guitar', ago: 1 * MINUTE },
      { member: 'tae', version: 'v1.1', note: '드럼 킥 타이밍 -0.04s 보정', part: 'Drums', ago: 2 * HOUR },
      { member: 'tae', version: 'v1.0', note: '첫 드럼 트랙 올림. 메트로놈 90', part: 'Drums', ago: 1 * DAY },
      { member: 'mina', version: 'v0.1', note: '합주 팀 개설 · 곡 정함', ago: 2 * DAY },
    ],
  },
  {
    name: '야근 시티팝',
    song: 'Plastic Love',
    artist: 'Mariya Takeuchi',
    bpm: 103,
    cover: 0xffd8d9d2,
    owner: 'soo',
    members: ['soo', 'hye', 'dan', 'me'],
    tracks: [
      { part: 'Drums', partKo: '드럼', glyph: 'drum', member: 'soo', offset: 0, note: '4비트 셔플로' },
      { part: 'Bass', partKo: '베이스', glyph: 'audio-lines', member: 'hye', offset: 10, note: '슬랩 라인' },
      { part: 'Keys', partKo: '건반', glyph: 'piano', member: 'dan', offset: -10, note: '로즈 톤' },
      { part: 'Guitar', partKo: '기타', glyph: 'guitar' },
      { part: 'Vocal', partKo: '보컬', glyph: 'audio-lines' },
    ],
    timeline: [
      { member: 'dan', version: 'v1.4', note: '건반 로즈 톤으로 교체', part: 'Keys', ago: 5 * HOUR },
      { member: 'hye', version: 'v1.2', note: '베이스 슬랩 라인 추가', part: 'Bass', ago: 1 * DAY + 3 * HOUR },
      { member: 'soo', version: 'v1.0', note: '합주 팀 개설 · 드럼 먼저', part: 'Drums', ago: 3 * DAY },
    ],
  },
  {
    name: '새벽 로파이',
    song: '비 오는 골목',
    artist: '원곡 · 단',
    bpm: 72,
    cover: 0xffdfe2dd,
    owner: 'dan',
    members: ['dan', 'me'],
    tracks: [
      { part: 'Keys', partKo: '건반', glyph: 'piano', member: 'dan', offset: 0, note: '비 내리는 패드' },
      { part: 'Drums', partKo: '드럼', glyph: 'drum' },
      { part: 'Bass', partKo: '베이스', glyph: 'audio-lines' },
    ],
    timeline: [
      { member: 'dan', version: 'v1.0', note: '건반 패드 깔았어요', part: 'Keys', ago: 1 * DAY },
      { member: 'dan', version: 'v0.1', note: '합주 팀 개설', ago: 4 * DAY },
    ],
  },
];

async function main() {
  const ds = await buildDataSource().initialize();
  const users = ds.getRepository(UserEntity);
  const teams = ds.getRepository(TeamEntity);
  const members = ds.getRepository(TeamMemberEntity);
  const tracks = ds.getRepository(TrackEntity);
  const commits = ds.getRepository(CommitEntity);

  if (await users.findOne({ where: { email: PEOPLE.me.email } })) {
    console.log('Seed skipped — demo account already exists.');
    await ds.destroy();
    return;
  }

  const passwordHash = await bcrypt.hash(PASSWORD, 10);

  // People → user rows (keyed for cross-reference below).
  const id: Record<string, string> = {};
  for (const [key, p] of Object.entries(PEOPLE)) {
    const u = await users.save(
      users.create({
        name: p.name,
        email: p.email,
        passwordHash,
        initial: initialOf(p.name),
        color: String(avatarColor(p.email)),
      }),
    );
    id[key] = u.id;
  }

  const now = Date.now();
  for (const spec of TEAMS) {
    const team = await teams.save(
      teams.create({
        name: spec.name,
        song: spec.song,
        artist: spec.artist,
        bpm: spec.bpm,
        coverColor: String(spec.cover),
        ownerId: id[spec.owner],
      }),
    );

    // Roster in listed order (joinedAt spaced so order is stable).
    let joinOffset = spec.members.length;
    for (const key of spec.members) {
      await members.save(
        members.create({
          teamId: team.id,
          userId: id[key],
          joinedAt: new Date(now - joinOffset-- * 1000),
        }),
      );
    }

    await tracks.save(
      spec.tracks.map((t, i) =>
        tracks.create({
          teamId: team.id,
          part: t.part,
          partKo: t.partKo,
          instrument: t.glyph,
          status: t.member ? 'ready' : 'open',
          memberId: t.member ? id[t.member] : null,
          syncOffsetMs: t.offset ?? 0,
          note: t.note ?? null,
          position: i,
        }),
      ),
    );

    await commits.save(
      spec.timeline.map((c) =>
        commits.create({
          teamId: team.id,
          memberId: id[c.member],
          version: c.version,
          note: c.note,
          part: c.part ?? null,
          createdAt: new Date(now - c.ago),
        }),
      ),
    );

    console.log(`Seeded team: ${spec.name}`);
  }

  console.log(
    `\nDone. Demo login → email: ${PEOPLE.me.email}  password: ${PASSWORD}`,
  );
  await ds.destroy();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
