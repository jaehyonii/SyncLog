import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { MoreThanOrEqual, Repository } from 'typeorm';
import { userToPerson } from '../teams/serializers';
import {
  NotificationEntity,
  NotificationType,
} from './entities/notification.entity';

/** Fields needed to fan one event out to a set of recipients. */
export interface NotifyParams {
  recipientIds: string[];
  actorId: string;
  teamId: string | null;
  teamName: string;
  type: NotificationType;
  title: string;
  body: string;
}

/** Maps a notification row to the JSON the Flutter client deserializes. */
function notificationToJson(n: NotificationEntity) {
  return {
    id: n.id,
    type: n.type,
    title: n.title,
    body: n.body,
    teamId: n.teamId,
    teamName: n.teamName,
    actor: userToPerson(n.actor),
    read: n.read,
    createdAt: n.createdAt.toISOString(),
  };
}

/**
 * Activity-feed store. `TeamsService` calls [notify] when a team event happens;
 * the client reads its own feed via the controller. There is no realtime push —
 * the app polls on open.
 */
@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(NotificationEntity)
    private readonly notifications: Repository<NotificationEntity>,
  ) {}

  /** Create one notification per recipient (the actor never notifies itself). */
  async notify(params: NotifyParams): Promise<void> {
    const recipients = params.recipientIds.filter((id) => id !== params.actorId);
    if (recipients.length === 0) return;
    const rows = recipients.map((userId) =>
      this.notifications.create({
        userId,
        actorId: params.actorId,
        teamId: params.teamId,
        teamName: params.teamName,
        type: params.type,
        title: params.title,
        body: params.body,
      }),
    );
    await this.notifications.save(rows);
  }

  /**
   * Deliver one notification straight to a single user (no actor-self filter).
   * Used for system nudges like upload reminders, where the recipient is also
   * recorded as the actor so the avatar/relation stays valid.
   */
  async remind(params: {
    userId: string;
    teamId: string | null;
    teamName: string;
    title: string;
    body: string;
  }): Promise<void> {
    await this.notifications.save(
      this.notifications.create({
        userId: params.userId,
        actorId: params.userId,
        teamId: params.teamId,
        teamName: params.teamName,
        type: 'reminder',
        title: params.title,
        body: params.body,
      }),
    );
  }

  /**
   * True if the user already has a reminder for [teamId] created since [since].
   * Lets the scheduler avoid stacking duplicate nudges for the same part/day.
   */
  async hasReminderSince(
    userId: string,
    teamId: string | null,
    since: Date,
  ): Promise<boolean> {
    const existing = await this.notifications.findOne({
      where: {
        userId,
        teamId: teamId ?? undefined,
        type: 'reminder',
        createdAt: MoreThanOrEqual(since),
      },
    });
    return existing != null;
  }

  /** The user's notifications, newest first (capped). */
  async listForUser(userId: string) {
    const rows = await this.notifications.find({
      where: { userId },
      relations: { actor: true },
      order: { createdAt: 'DESC' },
      take: 100,
    });
    return rows.map(notificationToJson);
  }

  /** Mark every unread notification read, then return the refreshed list. */
  async markAllRead(userId: string) {
    await this.notifications.update({ userId, read: false }, { read: true });
    return this.listForUser(userId);
  }
}
