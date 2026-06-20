import { UserEntity } from '../users/user.entity';
import { CommitEntity } from './entities/commit.entity';
import { TeamEntity } from './entities/team.entity';
import { TrackEntity } from './entities/track.entity';

/**
 * Maps DB entities to the exact JSON the Flutter client deserializes. The
 * canonical shapes live in `FE/lib/domain/entities/*.dart` (`*.fromJson`); keep
 * these in lockstep with those.
 */

export function userToPerson(u: UserEntity) {
  return {
    id: u.id,
    name: u.name,
    initial: u.initial,
    color: Number(u.color), // bigint comes back as a string from pg
    email: u.email,
  };
}

export function trackToJson(t: TrackEntity) {
  return {
    id: t.id,
    part: t.part,
    partKo: t.partKo,
    instrument: t.instrument,
    status: t.status,
    member: t.member ? userToPerson(t.member) : null,
    syncOffsetMs: t.syncOffsetMs,
    videoUrl: t.videoUrl ?? null,
    localPath: null, // client-only field; never set by the server
    note: t.note ?? null,
  };
}

export function commitToJson(c: CommitEntity) {
  return {
    id: c.id,
    member: userToPerson(c.member),
    version: c.version,
    note: c.note,
    part: c.part ?? null,
    createdAt: c.createdAt.toISOString(),
  };
}

/**
 * Full team payload. Sorts the loaded relations to match client expectations:
 * members creator-first (joinedAt asc), tracks by slot position, timeline
 * newest-first (so `timeline.first` is the latest version).
 */
export function teamToJson(t: TeamEntity) {
  const members = [...(t.members ?? [])]
    .sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime())
    .map((m) => userToPerson(m.user));

  const tracks = [...(t.tracks ?? [])]
    .sort((a, b) => a.position - b.position)
    .map(trackToJson);

  const timeline = [...(t.timeline ?? [])]
    .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
    .map(commitToJson);

  return {
    id: t.id,
    name: t.name,
    song: t.song,
    artist: t.artist,
    bpm: t.bpm,
    members,
    coverColor: Number(t.coverColor),
    tracks,
    timeline,
    inviteCode: t.inviteCode ?? null,
  };
}
