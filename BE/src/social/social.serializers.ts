import { UserEntity } from '../users/user.entity';
import { userToPerson } from '../teams/serializers';

/**
 * A user's public profile: their Person fields plus social counts, whether the
 * viewer follows them, and their ensemble posts. Matches the Flutter
 * `UserProfile.fromJson`.
 */
export function profileToJson(
  user: UserEntity,
  opts: {
    followerCount: number;
    followingCount: number;
    isFollowing: boolean;
    ensembles: unknown[];
  },
) {
  return {
    ...userToPerson(user),
    followerCount: opts.followerCount,
    followingCount: opts.followingCount,
    isFollowing: opts.isFollowing,
    ensembles: opts.ensembles,
  };
}
