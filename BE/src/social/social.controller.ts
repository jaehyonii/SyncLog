import {
  Controller,
  Delete,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UserEntity } from '../users/user.entity';
import { SocialService } from './social.service';

/**
 *   POST   /api/v1/users/:id/follow    -> { isFollowing, followerCount }
 *   DELETE /api/v1/users/:id/follow    -> { isFollowing, followerCount }
 *   GET    /api/v1/users/:id/followers -> Person[]
 *   GET    /api/v1/users/:id/following -> Person[]
 *   GET    /api/v1/users/:id           -> UserProfile
 *   GET    /api/v1/feed                -> Ensemble[]  (home feed)
 */
@Controller()
@UseGuards(JwtAuthGuard)
export class SocialController {
  constructor(private readonly social: SocialService) {}

  @Post('users/:id/follow')
  follow(@CurrentUser() user: UserEntity, @Param('id') id: string) {
    return this.social.follow(user, id);
  }

  @Delete('users/:id/follow')
  unfollow(@CurrentUser() user: UserEntity, @Param('id') id: string) {
    return this.social.unfollow(user, id);
  }

  @Get('users/:id/followers')
  followers(@Param('id') id: string) {
    return this.social.followers(id);
  }

  @Get('users/:id/following')
  following(@Param('id') id: string) {
    return this.social.following(id);
  }

  @Get('users/:id')
  profile(@CurrentUser() user: UserEntity, @Param('id') id: string) {
    return this.social.profile(user.id, id);
  }

  @Get('feed')
  feed(@CurrentUser() user: UserEntity) {
    return this.social.homeFeed(user.id);
  }
}
