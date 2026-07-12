import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { EnsembleEntity } from '../ensembles/entities/ensemble.entity';
import { NotificationsModule } from '../notifications/notifications.module';
import { TeamMemberEntity } from '../teams/entities/team-member.entity';
import { UserEntity } from '../users/user.entity';
import { FollowEntity } from './entities/follow.entity';
import { SocialController } from './social.controller';
import { SocialService } from './social.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      FollowEntity,
      EnsembleEntity,
      TeamMemberEntity,
      UserEntity,
    ]),
    // For the 'jwt' guard used by the controller.
    AuthModule,
    // For the "started following you" notification.
    NotificationsModule,
  ],
  controllers: [SocialController],
  providers: [SocialService],
})
export class SocialModule {}
