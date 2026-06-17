import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { coverFor, fmtOffset, INSTRUMENT_LINEUP, nextVersion } from '../common/sync';
import { UserEntity } from '../users/user.entity';
import { CreateTeamDto } from './dto/create-team.dto';
import { CommitEntity } from './entities/commit.entity';
import { TeamMemberEntity } from './entities/team-member.entity';
import { TeamEntity } from './entities/team.entity';
import { TrackEntity } from './entities/track.entity';
import { teamToJson } from './serializers';

/** Fully-hydrated relations needed to serialize a team. */
const TEAM_RELATIONS = {
  members: { user: true },
  tracks: { member: true },
  timeline: { member: true },
};

/** Multipart fields the client sends with a recorded take. */
export interface RecordTakeFields {
  track_id?: string;
  sync_offset_ms?: string;
  member_id?: string;
  note?: string;
}

/**
 * Team store and the server-side port of the client's repository logic
 * (`FE/lib/data/repositories/team_repository_impl.dart`): creating a team seeds
 * open instrument slots + a v0.1 commit; recording a take fills a slot, bumps
 * the version, and appends a commit. The server owns all identity and state.
 */
@Injectable()
export class TeamsService {
  constructor(
    @InjectRepository(TeamEntity)
    private readonly teams: Repository<TeamEntity>,
    @InjectRepository(TrackEntity)
    private readonly tracks: Repository<TrackEntity>,
    @InjectRepository(CommitEntity)
    private readonly commits: Repository<CommitEntity>,
    @InjectRepository(TeamMemberEntity)
    private readonly members: Repository<TeamMemberEntity>,
  ) {}

  /** Teams the user belongs to, newest first. */
  async listForUser(userId: string) {
    const memberships = await this.members.find({ where: { userId } });
    const ids = memberships.map((m) => m.teamId);
    if (ids.length === 0) return [];

    const teams = await this.teams.find({
      where: { id: In(ids) },
      relations: TEAM_RELATIONS,
    });
    teams.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return teams.map(teamToJson);
  }

  /** One team the user belongs to; 404 (not 403) if missing or not a member. */
  async getForUser(teamId: string, userId: string) {
    const team = await this.loadTeam(teamId);
    if (!team || !team.members.some((m) => m.userId === userId)) {
      throw new NotFoundException('요청한 항목을 찾을 수 없어요.');
    }
    return teamToJson(team);
  }

  async create(user: UserEntity, dto: CreateTeamDto) {
    const count = Math.min(
      Math.max(dto.memberCount ?? dto.tracks?.length ?? 4, 1),
      8,
    );
    const song = dto.song?.trim() ?? '';
    const teamCount = await this.teams.count();

    const team = await this.teams.save(
      this.teams.create({
        name: dto.name.trim() || '새 합주 팀',
        song: song || '곡 미정',
        artist: dto.artist?.trim() ?? '',
        bpm: dto.bpm ?? 90,
        coverColor: String(dto.coverColor ?? coverFor(teamCount)),
        ownerId: user.id,
      }),
    );

    await this.members.save(
      this.members.create({ teamId: team.id, userId: user.id }),
    );

    const slots = Array.from({ length: count }, (_, i) => {
      const preset = INSTRUMENT_LINEUP[i % INSTRUMENT_LINEUP.length];
      return this.tracks.create({
        teamId: team.id,
        part: preset.part,
        partKo: preset.partKo,
        instrument: preset.glyph,
        status: 'open',
        position: i,
        syncOffsetMs: 0,
      });
    });
    await this.tracks.save(slots);

    await this.commits.save(
      this.commits.create({
        teamId: team.id,
        memberId: user.id,
        version: 'v0.1',
        note: song ? '합주 팀 개설 · 곡 정함' : '합주 팀 개설',
      }),
    );

    return this.getForUser(team.id, user.id);
  }

  /**
   * Fill a track with the user's take: store the video, mark the slot ready,
   * bump the team version, and append a commit. The actor is the authenticated
   * user (the multipart `member_id` is ignored in favor of the token).
   */
  async recordTake(
    user: UserEntity,
    teamId: string,
    fields: RecordTakeFields,
    videoUrl: string | null,
  ) {
    const team = await this.teams.findOne({ where: { id: teamId } });
    if (!team) throw new NotFoundException('요청한 항목을 찾을 수 없어요.');

    const track = await this.tracks.findOne({
      where: { id: fields.track_id ?? '', teamId },
    });
    if (!track) throw new NotFoundException('요청한 항목을 찾을 수 없어요.');

    const syncOffsetMs = Number.parseInt(fields.sync_offset_ms ?? '0', 10) || 0;
    const note = fields.note?.trim();

    track.status = 'ready';
    track.memberId = user.id;
    track.syncOffsetMs = syncOffsetMs;
    if (videoUrl) track.videoUrl = videoUrl;
    track.note = note && note.length > 0 ? note : `${track.partKo} 파트 추가`;
    await this.tracks.save(track);

    // A recorder who wasn't on the roster joins it (mirrors the client).
    const onRoster = await this.members.findOne({
      where: { teamId, userId: user.id },
    });
    if (!onRoster) {
      await this.members.save(
        this.members.create({ teamId, userId: user.id }),
      );
    }

    const latest = await this.commits.findOne({
      where: { teamId },
      order: { createdAt: 'DESC' },
    });
    await this.commits.save(
      this.commits.create({
        teamId,
        memberId: user.id,
        version: nextVersion(latest?.version ?? null),
        note:
          note && note.length > 0
            ? note
            : `${track.partKo} 파트 추가 · 싱크 ${fmtOffset(syncOffsetMs)}`,
        part: track.part,
      }),
    );

    return this.getForUser(teamId, user.id);
  }

  private loadTeam(teamId: string) {
    return this.teams.findOne({
      where: { id: teamId },
      relations: TEAM_RELATIONS,
    });
  }
}
