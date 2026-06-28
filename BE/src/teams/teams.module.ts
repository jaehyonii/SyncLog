import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { CommitEntity } from './entities/commit.entity';
import { TeamMemberEntity } from './entities/team-member.entity';
import { TeamEntity } from './entities/team.entity';
import { TrackEntity } from './entities/track.entity';
import { TeamsController } from './teams.controller';
import { TeamsService } from './teams.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      TeamEntity,
      TrackEntity,
      CommitEntity,
      TeamMemberEntity,
    ]),
    // For the 'jwt' guard/strategy used by the controller.
    AuthModule,
    // For fanning team events (joins, takes) out to members as notifications.
    NotificationsModule,
  ],
  controllers: [TeamsController],
  providers: [TeamsService],
})
export class TeamsModule {}
