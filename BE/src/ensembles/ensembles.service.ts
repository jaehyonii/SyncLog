import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { isSameDay } from '../common/sync';
import { NotificationsService } from '../notifications/notifications.service';
import { TeamMemberEntity } from '../teams/entities/team-member.entity';
import { TeamEntity } from '../teams/entities/team.entity';
import { TrackEntity } from '../teams/entities/track.entity';
import { userToPerson } from '../teams/serializers';
import { EnsembleRenderService } from './ensemble-render.service';
import { ensembleToJson } from './ensemble.serializers';
import { EnsembleEntity } from './entities/ensemble.entity';

/**
 * Owns the daily-ensemble lifecycle: a 23:00 (Asia/Seoul) cron closes each
 * day's takes into ONE composited ensemble video per team (via
 * `EnsembleRenderService`), stores it as a public post, and nudges the roster.
 * Rendering is idempotent per (team, day) so an accidental re-fire — or the
 * manual `/ensembles/run` trigger — never double-renders.
 */
@Injectable()
export class EnsemblesService {
  private readonly logger = new Logger(EnsemblesService.name);

  constructor(
    @InjectRepository(EnsembleEntity)
    private readonly ensembles: Repository<EnsembleEntity>,
    @InjectRepository(TrackEntity)
    private readonly tracks: Repository<TrackEntity>,
    @InjectRepository(TeamMemberEntity)
    private readonly members: Repository<TeamMemberEntity>,
    @InjectRepository(TeamEntity)
    private readonly teams: Repository<TeamEntity>,
    private readonly notifications: NotificationsService,
    private readonly render: EnsembleRenderService,
  ) {}

  /** 'YYYY-MM-DD' in server-local time (container TZ=Asia/Seoul, like isSameDay). */
  private dayKey(d: Date): string {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  /** Daily close at 23:00 KST — same slot the upload reminder already uses. */
  @Cron('0 23 * * *', { name: 'ensemble-render-23' })
  async runDaily(): Promise<void> {
    const rendered = await this.runForDay(new Date());
    this.logger.log(`[cron] rendered ${rendered} ensemble(s)`);
  }

  /**
   * Render today's ensemble for every team that has a take today (or just
   * [teamId] if given). Returns how many were newly rendered. Teams run
   * sequentially so one heavy ffmpeg job at a time and one failure can't abort
   * the sweep.
   */
  async runForDay(now: Date, teamId?: string): Promise<number> {
    const day = this.dayKey(now);
    const teams = teamId
      ? await this.teams.findBy({ id: teamId })
      : await this.teamsWithTakesToday(now);

    let rendered = 0;
    for (const team of teams) {
      try {
        if (await this.renderTeamDay(team, day, now)) rendered++;
      } catch (e) {
        this.logger.error(`render failed for team ${team.id}: ${String(e)}`);
      }
    }
    return rendered;
  }

  /** Distinct teams that have at least one ready take uploaded today. */
  private async teamsWithTakesToday(now: Date): Promise<TeamEntity[]> {
    const ready = await this.tracks.find({
      where: { status: 'ready' },
      relations: { team: true },
    });
    const byTeam = new Map<string, TeamEntity>();
    for (const t of ready) {
      if (!t.videoUrl || !t.lastUploadedAt) continue;
      if (!isSameDay(t.lastUploadedAt, now)) continue;
      if (t.team) byTeam.set(t.teamId, t.team);
    }
    return [...byTeam.values()];
  }

  /**
   * Idempotently render one team's ensemble for [day]. Returns true only when a
   * new video was produced. Skips if a ready/rendering post already exists;
   * re-attempts a previously failed one.
   */
  private async renderTeamDay(
    team: TeamEntity,
    day: string,
    now: Date,
  ): Promise<boolean> {
    const existing = await this.ensembles.findOne({
      where: { teamId: team.id, day },
    });
    if (existing && existing.status !== 'failed') return false; // ready or in-flight

    // Snapshot the roster (creator-first) as Person objects for the feed card.
    const roster = await this.members.find({
      where: { teamId: team.id },
      relations: { user: true },
    });
    const memberSnapshot = [...roster]
      .sort((a, b) => a.joinedAt.getTime() - b.joinedAt.getTime())
      .map((m) => userToPerson(m.user));

    // Claim the (team, day) slot as 'rendering' (unique index guards races).
    let row = existing;
    if (!row) {
      try {
        row = await this.ensembles.save(
          this.ensembles.create({
            teamId: team.id,
            day,
            status: 'rendering',
            videoUrl: null,
            thumbnailUrl: null,
            teamName: team.name,
            song: team.song,
            coverColor: String(team.coverColor),
            members: memberSnapshot,
          }),
        );
      } catch {
        // Lost the race — another run already inserted it. Leave it to them.
        return false;
      }
    } else {
      row.status = 'rendering';
      row.members = memberSnapshot;
      row.teamName = team.name;
      row.song = team.song;
      row.coverColor = String(team.coverColor);
      await this.ensembles.save(row);
    }

    // Gather today's ready takes for this team.
    const teamTracks = await this.tracks.find({
      where: { teamId: team.id, status: 'ready' },
      order: { position: 'ASC' },
    });
    const todays = teamTracks.filter(
      (t) => t.videoUrl && t.lastUploadedAt && isSameDay(t.lastUploadedAt, now),
    );
    if (todays.length === 0) {
      row.status = 'failed';
      await this.ensembles.save(row);
      return false;
    }

    try {
      const result = await this.render.renderDay(
        todays.map((t) => ({
          videoUrl: t.videoUrl as string,
          syncOffsetMs: t.syncOffsetMs,
        })),
      );
      row.videoUrl = result.videoUrl;
      row.thumbnailUrl = result.thumbnailUrl;
      row.status = 'ready';
      await this.ensembles.save(row);

      await this.notifications.notify({
        recipientIds: roster.map((m) => m.userId),
        actorId: team.ownerId,
        teamId: team.id,
        teamName: team.name,
        type: 'ensemble',
        title: '오늘의 합주 영상이 나왔어요',
        body: `‘${team.name}’ 오늘의 합주 영상이 완성됐어요. 피드에서 확인해 보세요.`,
      });
      return true;
    } catch (e) {
      row.status = 'failed';
      await this.ensembles.save(row);
      this.logger.error(`ffmpeg render failed for team ${team.id}: ${String(e)}`);
      return false;
    }
  }

  /** All public ensembles, newest first (the 탐색/explore feed). */
  async exploreFeed() {
    const rows = await this.ensembles.find({
      where: { status: 'ready' },
      order: { createdAt: 'DESC' },
      take: 30,
    });
    return rows.map(ensembleToJson);
  }
}
