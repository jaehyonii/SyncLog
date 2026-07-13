import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { EnsembleEntity } from '../ensembles/entities/ensemble.entity';
import { ensembleToJson } from '../ensembles/ensemble.serializers';
import { NotificationsService } from '../notifications/notifications.service';
import { TeamMemberEntity } from '../teams/entities/team-member.entity';
import { userToPerson } from '../teams/serializers';
import { UserEntity } from '../users/user.entity';
import { FollowEntity } from './entities/follow.entity';
import { profileToJson } from './social.serializers';

/**
 * The social graph: follow/unfollow, user profiles, and the two ensemble feeds
 * a follow model produces — the home feed (ensembles from teams that people I
 * follow are in) reads the follow graph, while explore lives on
 * `EnsemblesService`. Everything is public (no privacy checks).
 */
@Injectable()
export class SocialService {
  constructor(
    @InjectRepository(FollowEntity)
    private readonly follows: Repository<FollowEntity>,
    @InjectRepository(EnsembleEntity)
    private readonly ensembles: Repository<EnsembleEntity>,
    @InjectRepository(TeamMemberEntity)
    private readonly members: Repository<TeamMemberEntity>,
    @InjectRepository(UserEntity)
    private readonly users: Repository<UserEntity>,
    private readonly notifications: NotificationsService,
  ) {}

  async follow(me: UserEntity, targetId: string) {
    if (me.id === targetId) {
      throw new BadRequestException('자기 자신은 팔로우할 수 없어요.');
    }
    const target = await this.users.findOneBy({ id: targetId });
    if (!target) throw new NotFoundException('사용자를 찾을 수 없어요.');

    const already = await this.follows.countBy({
      followerId: me.id,
      followeeId: targetId,
    });
    if (!already) {
      await this.follows.save(
        this.follows.create({ followerId: me.id, followeeId: targetId }),
      );
      await this.notifications.notify({
        recipientIds: [targetId],
        actorId: me.id,
        teamId: null,
        teamName: '',
        type: 'follow',
        title: `${me.name}님이 팔로우했어요`,
        body: `${me.name}님이 회원님을 팔로우하기 시작했어요.`,
      });
    }
    return {
      isFollowing: true,
      followerCount: await this.follows.countBy({ followeeId: targetId }),
    };
  }

  async unfollow(me: UserEntity, targetId: string) {
    await this.follows.delete({ followerId: me.id, followeeId: targetId });
    return {
      isFollowing: false,
      followerCount: await this.follows.countBy({ followeeId: targetId }),
    };
  }

  async profile(meId: string, id: string) {
    const user = await this.users.findOneBy({ id });
    if (!user) throw new NotFoundException('사용자를 찾을 수 없어요.');

    const [followerCount, followingCount, isFollowing, ensembles] =
      await Promise.all([
        this.follows.countBy({ followeeId: id }),
        this.follows.countBy({ followerId: id }),
        meId === id
          ? Promise.resolve(0)
          : this.follows.countBy({ followerId: meId, followeeId: id }),
        this.profileEnsembles(id),
      ]);

    return profileToJson(user, {
      followerCount,
      followingCount,
      isFollowing: (isFollowing as number) > 0,
      ensembles,
    });
  }

  /** Ready ensembles from every team the user is in, newest first. */
  private async profileEnsembles(userId: string) {
    const teamIds = (
      await this.members.find({ where: { userId }, select: { teamId: true } })
    ).map((m) => m.teamId);
    if (teamIds.length === 0) return [];
    const rows = await this.ensembles.find({
      where: { teamId: In(teamIds), status: 'ready' },
      order: { createdAt: 'DESC' },
      take: 30,
    });
    return rows.map(ensembleToJson);
  }

  /** Home feed: ready ensembles from teams whose members I follow, newest first. */
  async homeFeed(meId: string) {
    const followeeIds = (
      await this.follows.find({
        where: { followerId: meId },
        select: { followeeId: true },
      })
    ).map((f) => f.followeeId);
    if (followeeIds.length === 0) return [];

    const teamIds = [
      ...new Set(
        (
          await this.members.find({
            where: { userId: In(followeeIds) },
            select: { teamId: true },
          })
        ).map((m) => m.teamId),
      ),
    ];
    if (teamIds.length === 0) return [];

    const rows = await this.ensembles.find({
      where: { teamId: In(teamIds), status: 'ready' },
      order: { createdAt: 'DESC' },
      take: 50,
    });
    return rows.map(ensembleToJson);
  }

  async followers(id: string) {
    const rows = await this.follows.find({
      where: { followeeId: id },
      relations: { follower: true },
      order: { createdAt: 'DESC' },
    });
    return rows.map((f) => userToPerson(f.follower));
  }

  async following(id: string) {
    const rows = await this.follows.find({
      where: { followerId: id },
      relations: { followee: true },
      order: { createdAt: 'DESC' },
    });
    return rows.map((f) => userToPerson(f.followee));
  }
}
