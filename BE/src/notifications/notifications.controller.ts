import { Controller, Get, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UserEntity } from '../users/user.entity';
import { NotificationsService } from './notifications.service';

/**
 *   GET  /api/v1/notifications        -> Notification[]  (the user's feed)
 *   POST /api/v1/notifications/read   -> Notification[]  (mark all read)
 */
@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Get()
  list(@CurrentUser() user: UserEntity) {
    return this.notifications.listForUser(user.id);
  }

  @Post('read')
  markRead(@CurrentUser() user: UserEntity) {
    return this.notifications.markAllRead(user.id);
  }
}
