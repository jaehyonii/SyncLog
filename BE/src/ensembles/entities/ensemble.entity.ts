import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { TeamEntity } from '../../teams/entities/team.entity';

/** Serialized `Person` snapshot (matches `userToPerson`), stored inline. */
export interface EnsembleMember {
  id: string;
  name: string;
  initial: string;
  color: number;
  email: string | null;
}

/** Render lifecycle of a day's ensemble video. */
export type EnsembleStatus = 'rendering' | 'ready' | 'failed';

/**
 * One team's daily "post": the ffmpeg-composited ensemble video built from that
 * calendar day's part takes. The feed reads these heavily, so team fields and
 * the member roster are denormalized (snapshotted at render time) — a feed page
 * needs no joins and survives later team edits/deletes. Serialized to the client
 * by `ensembleToJson` to match the Flutter `Ensemble.fromJson`.
 */
@Entity('ensembles')
@Index(['teamId', 'day'], { unique: true }) // one post per team per day (idempotency)
export class EnsembleEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  teamId: string;

  @ManyToOne(() => TeamEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'teamId' })
  team: TeamEntity;

  /** Calendar day key 'YYYY-MM-DD' in the server timezone (Asia/Seoul). */
  @Column()
  day: string;

  @Column({ type: 'varchar', default: 'rendering' })
  status: EnsembleStatus;

  /** Public URL of the composited MP4; null until the render finishes. */
  @Column({ type: 'varchar', nullable: true })
  videoUrl: string | null;

  @Column({ type: 'varchar', nullable: true })
  thumbnailUrl: string | null;

  // --- Denormalized team snapshot (for feed cards, no join needed) ---
  @Column({ default: '' })
  teamName: string;

  @Column({ default: '' })
  song: string;

  /** Team cover color as 0xAARRGGBB (bigint, like Team.coverColor). */
  @Column({ type: 'bigint', default: 0 })
  coverColor: string;

  /** Roster snapshot as already-serialized Person objects. */
  @Column({ type: 'jsonb', default: () => "'[]'" })
  members: EnsembleMember[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;
}
