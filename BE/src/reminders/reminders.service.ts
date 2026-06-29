import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Not, Repository } from 'typeorm';
import { isSameDay } from '../common/sync';
import { NotificationsService } from '../notifications/notifications.service';
import { TrackEntity } from '../teams/entities/track.entity';

/**
 * Scheduled upload nudges. Twice a day (17:00 and 23:00) every part owner who
 * hasn't uploaded their part today gets a reminder notification. "Today" and the
 * trigger times follow the server timezone — the api container runs as
 * Asia/Seoul (see docker-compose), so these are 17:00 / 23:00 KST.
 */
@Injectable()
export class RemindersService {
  private readonly logger = new Logger(RemindersService.name);

  /** Skip a part already reminded within this window (re-fire / restart guard). */
  private static readonly DEDUPE_MS = 60 * 60 * 1000; // 1 hour

  constructor(
    @InjectRepository(TrackEntity)
    private readonly tracks: Repository<TrackEntity>,
    private readonly notifications: NotificationsService,
  ) {}

  @Cron('0 17 * * *', { name: 'upload-reminder-17' })
  async at17() {
    await this.sendPendingReminders('17:00');
  }

  @Cron('0 23 * * *', { name: 'upload-reminder-23' })
  async at23() {
    await this.sendPendingReminders('23:00');
  }

  /**
   * Notify every part owner whose part has no take today. Returns how many
   * reminders were sent. Idempotent within [DEDUPE_MS] per part so an accidental
   * re-fire doesn't stack duplicates (the two daily slots are 6h apart, so both
   * still go out).
   */
  async sendPendingReminders(slot: string): Promise<number> {
    const now = new Date();
    const since = new Date(now.getTime() - RemindersService.DEDUPE_MS);

    // Claimed parts (an owner exists) — open/unclaimed slots have nobody to nudge.
    const claimed = await this.tracks.find({
      where: { memberId: Not(IsNull()) },
      relations: { team: true },
    });
    const pending = claimed.filter(
      (t) => !t.lastUploadedAt || !isSameDay(t.lastUploadedAt, now),
    );

    let sent = 0;
    for (const t of pending) {
      if (!t.memberId) continue;
      if (await this.notifications.hasReminderSince(t.memberId, t.teamId, since)) {
        continue;
      }
      const teamName = t.team?.name ?? '합주 팀';
      await this.notifications.remind({
        userId: t.memberId,
        teamId: t.teamId,
        teamName,
        title: `오늘 ‘${t.partKo}’ 파트 아직이에요`,
        body: `‘${teamName}’에 오늘 ${t.partKo} 영상을 올려 합주를 채워 주세요.`,
      });
      sent++;
    }
    this.logger.log(`[${slot}] sent ${sent} upload reminder(s)`);
    return sent;
  }
}
