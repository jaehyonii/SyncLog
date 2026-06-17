import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { UserEntity } from '../../users/user.entity';
import { TeamEntity } from './team.entity';

/** 'ready' (filled with a take) or 'open' (an empty slot). Matches TrackStatus. */
export type TrackStatus = 'ready' | 'open';

/**
 * One cell of a team's multitrack — a single instrument part. Serialized by
 * `trackToJson` to match the Flutter `Track.fromJson` (note: `localPath` is a
 * client-only field and always serialized as null from the server).
 */
@Entity('tracks')
export class TrackEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  teamId: string;

  @ManyToOne(() => TeamEntity, (t) => t.tracks, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'teamId' })
  team: TeamEntity;

  @Column()
  part: string;

  @Column()
  partKo: string;

  @Column({ default: 'audio-lines' })
  instrument: string;

  @Column({ type: 'varchar', default: 'open' })
  status: TrackStatus;

  @Column({ type: 'uuid', nullable: true })
  memberId: string | null;

  @ManyToOne(() => UserEntity, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'memberId' })
  member: UserEntity | null;

  @Column({ type: 'int', default: 0 })
  syncOffsetMs: number;

  /** Remote video URL of the take; null for open slots. */
  @Column({ type: 'varchar', nullable: true })
  videoUrl: string | null;

  @Column({ type: 'varchar', nullable: true })
  note: string | null;

  /** Stable ordering within the team's multitrack. */
  @Column({ type: 'int', default: 0 })
  position: number;
}
