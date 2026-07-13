import { Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { EnsemblesService } from './ensembles.service';

/**
 *   GET  /api/v1/ensembles/explore  -> Ensemble[]  (all public daily ensembles)
 *   POST /api/v1/ensembles/run      -> { rendered } (run today's render sweep now;
 *        the same logic the 23:00 cron runs. Optional ?teamId= renders one team.)
 *
 * The run trigger awaits the ffmpeg render(s), so the request can be slow — it's
 * a testing/ops convenience, mirroring POST /reminders/run.
 */
@Controller('ensembles')
@UseGuards(JwtAuthGuard)
export class EnsemblesController {
  constructor(private readonly ensembles: EnsemblesService) {}

  @Get('explore')
  explore() {
    return this.ensembles.exploreFeed();
  }

  @Post('run')
  async run(@Query('teamId') teamId?: string) {
    const rendered = await this.ensembles.runForDay(new Date(), teamId);
    return { rendered };
  }
}
