import { Controller, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RemindersService } from './reminders.service';

/**
 *   POST /api/v1/reminders/run  -> { sent }   (run the "haven't uploaded today"
 *   sweep on demand; the same logic the 17:00/23:00 cron jobs run)
 */
@Controller('reminders')
@UseGuards(JwtAuthGuard)
export class RemindersController {
  constructor(private readonly reminders: RemindersService) {}

  @Post('run')
  async run() {
    const sent = await this.reminders.sendPendingReminders('manual');
    return { sent };
  }
}
