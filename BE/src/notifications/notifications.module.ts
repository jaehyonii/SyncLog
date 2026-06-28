import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from '../auth/auth.module';
import { NotificationEntity } from './entities/notification.entity';
import { NotificationsController } from './notifications.controller';
import { NotificationsService } from './notifications.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([NotificationEntity]),
    // For the 'jwt' guard/strategy used by the controller.
    AuthModule,
  ],
  controllers: [NotificationsController],
  providers: [NotificationsService],
  // Exported so TeamsService can fan team events out to members.
  exports: [NotificationsService],
})
export class NotificationsModule {}
