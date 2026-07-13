import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { UserEntity } from '../../users/user.entity';

/** What a notification is about. Mirrors the client's `NotificationType`. */
export type NotificationType =
  | 'join'
  | 'take'
  | 'reminder'
  | 'follow'
  | 'ensemble';

/**
 * An activity notification delivered to one team member: someone joined a team
 * they're in (`join`), someone stacked a new take onto a shared timeline
 * (`take`), or a scheduled nudge that they haven't uploaded their part today
 * (`reminder`). Generated server-side and serialized to the client by
 * `notificationToJson`.
 */
@Entity('notifications')
export class NotificationEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** The recipient. Indexed because every fetch is "my notifications". */
  @Index()
  @Column({ type: 'uuid' })
  userId: string;

  /** Who triggered it (the joiner / the recorder). */
  @Column({ type: 'uuid' })
  actorId: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'actorId' })
  actor: UserEntity;

  /** The team it relates to. Denormalized name so it survives team deletion. */
  @Column({ type: 'uuid', nullable: true })
  teamId: string | null;

  @Column({ default: '' })
  teamName: string;

  @Column({ type: 'varchar' })
  type: NotificationType;

  @Column()
  title: string;

  @Column({ type: 'text' })
  body: string;

  @Column({ default: false })
  read: boolean;

  // timestamptz so absolute-time window queries (e.g. reminder dedupe) compare
  // correctly regardless of the server timezone.
  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
