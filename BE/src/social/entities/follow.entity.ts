import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryColumn,
} from 'typeorm';
import { UserEntity } from '../../users/user.entity';

/**
 * A directed follow edge: `followerId` follows `followeeId`. Modeled on
 * `TeamMemberEntity` — a composite primary key gives the pair uniqueness for
 * free (you can't follow someone twice). `followerId` leads the PK so "who do I
 * follow" lookups are index-served; an explicit index on `followeeId` covers
 * the reverse direction ("who follows X" / follower counts).
 */
@Entity('follows')
@Index(['followeeId'])
export class FollowEntity {
  @PrimaryColumn({ type: 'uuid' })
  followerId: string;

  @PrimaryColumn({ type: 'uuid' })
  followeeId: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt: Date;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'followerId' })
  follower: UserEntity;

  @ManyToOne(() => UserEntity, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'followeeId' })
  followee: UserEntity;
}
