import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { CommitEntity } from './commit.entity';
import { TeamMemberEntity } from './team-member.entity';
import { TrackEntity } from './track.entity';

/**
 * A 합주 팀 (ensemble team): one target song, a fixed tempo, a roster, a
 * multitrack of instrument parts, and a Git-style practice timeline. Serialized
 * to the client by `teamToJson` to match the Flutter `Team.fromJson`.
 */
@Entity('teams')
export class TeamEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ default: '' })
  song: string;

  @Column({ default: '' })
  artist: string;

  @Column({ type: 'int', default: 90 })
  bpm: number;

  /** Cover color as an 0xAARRGGBB int (bigint for the same reason as User.color). */
  @Column({ type: 'bigint' })
  coverColor: string;

  /** The creator; always also present in `members`. */
  @Column({ type: 'uuid' })
  ownerId: string;

  /**
   * Short shareable join code. Anyone who enters it joins the team's roster
   * (POST /teams/join). Nullable so existing rows survive the auto-sync; new
   * teams always get one, and old teams are backfilled on first open.
   */
  @Index({ unique: true })
  @Column({ type: 'varchar', length: 12, nullable: true })
  inviteCode: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @OneToMany(() => TeamMemberEntity, (m) => m.team)
  members: TeamMemberEntity[];

  @OneToMany(() => TrackEntity, (t) => t.team)
  tracks: TrackEntity[];

  @OneToMany(() => CommitEntity, (c) => c.team)
  timeline: CommitEntity[];
}
