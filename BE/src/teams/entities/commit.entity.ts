import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { UserEntity } from '../../users/user.entity';
import { TeamEntity } from './team.entity';

/**
 * One entry on a team's Git-style practice timeline — a versioned take with a
 * one-line note. Serialized by `commitToJson` to match the Flutter
 * `Commit.fromJson` (createdAt as ISO-8601).
 */
@Entity('commits')
export class CommitEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'uuid' })
  teamId: string;

  @ManyToOne(() => TeamEntity, (t) => t.timeline, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'teamId' })
  team: TeamEntity;

  @Column({ type: 'uuid' })
  memberId: string;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'memberId' })
  member: UserEntity;

  @Column()
  version: string;

  @Column({ type: 'text' })
  note: string;

  @Column({ type: 'varchar', nullable: true })
  part: string | null;

  // Settable (so seeds can backdate the timeline); defaults to insert time.
  @Column({ type: 'timestamptz', default: () => 'now()' })
  createdAt: Date;
}
