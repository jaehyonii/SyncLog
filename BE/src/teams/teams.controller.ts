import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { randomUUID } from 'node:crypto';
import { extname } from 'node:path';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UserEntity } from '../users/user.entity';
import { CreateTeamDto } from './dto/create-team.dto';
import { RecordTakeFields, TeamsService } from './teams.service';

/** Where recorded videos land (served statically at /uploads — see main.ts). */
export const UPLOAD_DIR = './uploads';

/**
 *   GET  /api/v1/teams              -> Team[]   (the user's teams)
 *   GET  /api/v1/teams/:id/stream   -> Team
 *   POST /api/v1/teams              -> Team     (create)
 *   POST /api/v1/teams/:id/record   -> Team     (multipart take upload)
 */
@Controller('teams')
@UseGuards(JwtAuthGuard)
export class TeamsController {
  constructor(
    private readonly teams: TeamsService,
    private readonly config: ConfigService,
  ) {}

  @Get()
  list(@CurrentUser() user: UserEntity) {
    return this.teams.listForUser(user.id);
  }

  @Get(':id/stream')
  stream(@CurrentUser() user: UserEntity, @Param('id') id: string) {
    return this.teams.getForUser(id, user.id);
  }

  @Post()
  create(@CurrentUser() user: UserEntity, @Body() dto: CreateTeamDto) {
    return this.teams.create(user, dto);
  }

  @Post(':id/record')
  @UseInterceptors(
    FileInterceptor('video', {
      storage: diskStorage({
        destination: UPLOAD_DIR,
        filename: (_req, file, cb) =>
          cb(null, `${randomUUID()}${extname(file.originalname) || '.mp4'}`),
      }),
      limits: { fileSize: 200 * 1024 * 1024 }, // 200 MB
    }),
  )
  record(
    @CurrentUser() user: UserEntity,
    @Param('id') id: string,
    @Body() body: RecordTakeFields,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    const videoUrl = file
      ? `${this.publicUrl()}/uploads/${file.filename}`
      : null;
    return this.teams.recordTake(user, id, body, videoUrl);
  }

  private publicUrl(): string {
    return this.config
      .get<string>('PUBLIC_URL', 'http://localhost:3000')
      .replace(/\/$/, '');
  }
}
