import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { TeamMemberEntity } from '../teams/entities/team-member.entity';
import { TeamEntity } from '../teams/entities/team.entity';
import { TrackEntity } from '../teams/entities/track.entity';
import { EnsembleRenderService } from './ensemble-render.service';
import { EnsemblesController } from './ensembles.controller';
import { EnsemblesService } from './ensembles.service';
import { EnsembleEntity } from './entities/ensemble.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      EnsembleEntity,
      TrackEntity,
      TeamMemberEntity,
      TeamEntity,
    ]),
    // For the 'jwt' guard used by the controller.
    AuthModule,
    // For the "ensemble ready" notification fan-out.
    NotificationsModule,
  ],
  controllers: [EnsemblesController],
  providers: [EnsemblesService, EnsembleRenderService],
  exports: [EnsemblesService],
})
export class EnsemblesModule {}
