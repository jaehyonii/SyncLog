import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import {
  coverFor,
  fmtOffset,
  INSTRUMENT_LINEUP,
  isSameDay,
  makeInviteCode,
  nextVersion,
} from '../common/sync';
import { NotificationsService } from '../notifications/notifications.service';
import { UserEntity } from '../users/user.entity';
import { CreateTeamDto, CreateTeamPartDto } from './dto/create-team.dto';
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
    private readonly notifications: NotificationsService,
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
    for (const team of teams) await this.ensureInviteCode(team); // backfill old rows
    teams.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return teams.map(teamToJson);
  }

  /** One team the user belongs to; 404 (not 403) if missing or not a member. */
  async getForUser(teamId: string, userId: string) {
    const team = await this.loadTeam(teamId);
    if (!team || !team.members.some((m) => m.userId === userId)) {
      throw new NotFoundException('요청한 항목을 찾을 수 없어요.');
    }
    await this.ensureInviteCode(team); // backfill teams seeded before invites
    return teamToJson(team);
  }

  /**
   * Join by code. A per-part code claims that exact part (sets the user as its
   * owner); a team-level code is still accepted as a legacy fallback that only
   * adds the user to the roster.
   */
  async joinByCode(user: UserEntity, rawCode: string) {
    const code = (rawCode ?? '').trim().toUpperCase();
    if (!code) throw new NotFoundException('초대 코드를 확인해 주세요.');

    // Per-part code: claim the specific slot.
    const track = await this.tracks.findOne({ where: { inviteCode: code } });
    if (track) {
      if (track.memberId && track.memberId !== user.id) {
        throw new ConflictException('이미 다른 멤버가 맡은 파트예요.');
      }
      const team = await this.teams.findOne({ where: { id: track.teamId } });
      if (!team) throw new NotFoundException('유효하지 않은 초대 코드예요.');

      await this.addToRoster(team, user);
      if (!track.memberId) {
        track.memberId = user.id;
        track.inviteCode = null; // code is spent once the part has an owner
        await this.tracks.save(track);
      }
      return this.getForUser(team.id, user.id);
    }

    // Legacy team-level code: roster-only join.
    const team = await this.teams.findOne({ where: { inviteCode: code } });
    if (!team) throw new NotFoundException('유효하지 않은 초대 코드예요.');
    await this.addToRoster(team, user);
    return this.getForUser(team.id, user.id);
  }

  /** Add a user to a team's roster (if new) and notify the existing members. */
  private async addToRoster(team: TeamEntity, user: UserEntity) {
    const already = await this.members.findOne({
      where: { teamId: team.id, userId: user.id },
    });
    if (already) return;

    // Existing roster (before this user joins) is who gets notified.
    const roster = await this.members.find({ where: { teamId: team.id } });
    await this.members.save(
      this.members.create({ teamId: team.id, userId: user.id }),
    );
    await this.notifications.notify({
      recipientIds: roster.map((m) => m.userId),
      actorId: user.id,
      teamId: team.id,
      teamName: team.name,
      type: 'join',
      title: `${user.name}님이 합류했어요`,
      body: `‘${team.name}’ 팀에 새 멤버가 들어왔어요.`,
    });
  }

  async create(user: UserEntity, dto: CreateTeamDto) {
    const song = dto.song?.trim() ?? '';
    const teamCount = await this.teams.count();
    const parts = this.resolveParts(dto);

    const team = await this.teams.save(
      this.teams.create({
        name: dto.name.trim() || '새 합주 팀',
        song: song || '곡 미정',
        artist: dto.artist?.trim() ?? '',
        bpm: dto.bpm ?? 90,
        coverColor: String(dto.coverColor ?? coverFor(teamCount)),
        ownerId: user.id,
        inviteCode: await this.uniqueCode(),
      }),
    );

    await this.members.save(
      this.members.create({ teamId: team.id, userId: user.id }),
    );

    // Build one track per defined part. The leader's part is claimed up front
    // (memberId set, no code); every other part gets its own invite code so a
    // specific member can be invited to that exact slot.
    const slots: TrackEntity[] = [];
    for (let i = 0; i < parts.length; i++) {
      const p = parts[i];
      slots.push(
        this.tracks.create({
          teamId: team.id,
          part: p.part,
          partKo: p.partKo,
          instrument: p.instrument,
          status: 'open',
          position: i,
          syncOffsetMs: 0,
          memberId: p.mine ? user.id : null,
          inviteCode: p.mine ? null : await this.uniqueCode(),
        }),
      );
    }
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
   * Normalize the requested parts into an ordered lineup. Uses the leader's
   * `parts` when given (display name + glyph + which one is theirs); otherwise
   * falls back to the default instrument lineup sized by `memberCount`. Exactly
   * one part is marked `mine` — the first `mine`, or slot 0 if none was flagged.
   */
  private resolveParts(dto: CreateTeamDto): Array<{
    part: string;
    partKo: string;
    instrument: string;
    mine: boolean;
  }> {
    const fromClient = (dto.parts ?? [])
      .map((p: CreateTeamPartDto) => ({
        name: (p.name ?? '').trim(),
        instrument: (p.instrument ?? '').trim() || 'audio-lines',
        mine: p.mine === true,
      }))
      .filter((p) => p.name.length > 0)
      .slice(0, 8);

    let lineup: Array<{ partKo: string; instrument: string; mine: boolean }>;
    if (fromClient.length > 0) {
      lineup = fromClient.map((p) => ({
        partKo: p.name,
        instrument: p.instrument,
        mine: p.mine,
      }));
    } else {
      const count = Math.min(
        Math.max(dto.memberCount ?? dto.tracks?.length ?? 4, 1),
        8,
      );
      lineup = Array.from({ length: count }, (_, i) => {
        const preset = INSTRUMENT_LINEUP[i % INSTRUMENT_LINEUP.length];
        return { partKo: preset.partKo, instrument: preset.glyph, mine: false };
      });
    }

    // Ensure exactly one part belongs to the leader.
    const firstMine = lineup.findIndex((p) => p.mine);
    const ownerIdx = firstMine >= 0 ? firstMine : 0;
    return lineup.map((p, i) => ({
      part: p.partKo,
      partKo: p.partKo,
      instrument: p.instrument,
      mine: i === ownerIdx,
    }));
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

    // You may only upload to your own part. The leader's part is claimed at
    // creation; everyone else claims theirs by joining with the part's code.
    if (!track.memberId) {
      throw new ForbiddenException(
        '먼저 파트 초대 코드로 이 파트에 참여해 주세요.',
      );
    }
    if (track.memberId !== user.id) {
      throw new ForbiddenException('본인 파트에만 업로드할 수 있어요.');
    }

    // One upload per calendar day per part; versions still accumulate.
    const now = new Date();
    if (track.lastUploadedAt && isSameDay(track.lastUploadedAt, now)) {
      throw new ConflictException(
        '오늘은 이미 이 파트를 올렸어요. 내일 새 버전을 올릴 수 있어요.',
      );
    }

    const syncOffsetMs = Number.parseInt(fields.sync_offset_ms ?? '0', 10) || 0;
    const note = fields.note?.trim();

    track.status = 'ready';
    track.syncOffsetMs = syncOffsetMs;
    if (videoUrl) track.videoUrl = videoUrl;
    track.note = note && note.length > 0 ? note : `${track.partKo} 파트 추가`;
    track.lastUploadedAt = now;
    await this.tracks.save(track);

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

    // Let the rest of the roster know a new take landed on the timeline.
    const roster = await this.members.find({ where: { teamId } });
    await this.notifications.notify({
      recipientIds: roster.map((m) => m.userId),
      actorId: user.id,
      teamId,
      teamName: team.name,
      type: 'take',
      title: `${user.name}님이 ${track.partKo} 파트를 올렸어요`,
      body:
        note && note.length > 0
          ? note
          : `‘${team.name}’에 새 버전이 추가됐어요.`,
    });

    return this.getForUser(teamId, user.id);
  }

  /**
   * Public feed: teams the user is NOT in that already have at least one take,
   * newest first. Invite codes are stripped — this is a browse-only view.
   */
  async discover(userId: string) {
    const memberships = await this.members.find({ where: { userId } });
    const mine = new Set(memberships.map((m) => m.teamId));

    const teams = await this.teams.find({ relations: TEAM_RELATIONS });
    return teams
      .filter((t) => !mine.has(t.id))
      .filter((t) => (t.tracks ?? []).some((tr) => tr.status === 'ready'))
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())
      .slice(0, 30)
      .map((t) => {
        const json = teamToJson(t);
        return {
          ...json,
          inviteCode: null,
          tracks: json.tracks.map((tr) => ({ ...tr, inviteCode: null })),
        };
      });
  }

  private loadTeam(teamId: string) {
    return this.teams.findOne({
      where: { id: teamId },
      relations: TEAM_RELATIONS,
    });
  }

  /** A fresh invite code not currently used by any team or part. */
  private async uniqueCode(): Promise<string> {
    for (let i = 0; i < 10; i++) {
      const code = makeInviteCode();
      const teamClash = await this.teams.findOne({
        where: { inviteCode: code },
      });
      if (teamClash) continue;
      const trackClash = await this.tracks.findOne({
        where: { inviteCode: code },
      });
      if (!trackClash) return code;
    }
    throw new Error('Could not allocate a unique invite code');
  }

  /** Give a pre-invites team a code on first access (mutates `team` in place). */
  private async ensureInviteCode(team: TeamEntity) {
    if (team.inviteCode) return;
    const code = await this.uniqueCode();
    await this.teams.update(team.id, { inviteCode: code });
    team.inviteCode = code;
  }
}
