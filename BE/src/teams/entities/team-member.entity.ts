import { Column, Entity, JoinColumn, ManyToOne, PrimaryColumn } from 'typeorm';
import { UserEntity } from '../../users/user.entity';
import { TeamEntity } from './team.entity';

/**
 * Roster join row. An explicit entity (rather than a plain ManyToOne join
 * table) so member order is stable — `joinedAt` preserves "creator first",
 * matching how the client lists `Team.members`.
 */
@Entity('team_members')
export class TeamMemberEntity {
  @PrimaryColumn({ type: 'uuid' })
  teamId: string;

  @PrimaryColumn({ type: 'uuid' })
  userId: string;

  // Settable (so seeds can order the roster); defaults to insert time.
  @Column({ type: 'timestamptz', default: () => 'now()' })
  joinedAt: Date;

  @ManyToOne(() => TeamEntity, (t) => t.members, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'teamId' })
  team: TeamEntity;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: UserEntity;
}
