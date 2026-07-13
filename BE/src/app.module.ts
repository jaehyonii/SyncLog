import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ScheduleModule } from '@nestjs/schedule';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { EnsemblesModule } from './ensembles/ensembles.module';
import { NotificationsModule } from './notifications/notifications.module';
import { RemindersModule } from './reminders/reminders.module';
import { SocialModule } from './social/social.module';
import { TeamsModule } from './teams/teams.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    // Drives the scheduled upload-reminder cron jobs (see RemindersService).
    ScheduleModule.forRoot(),
    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        host: config.get<string>('DB_HOST', 'localhost'),
        port: parseInt(config.get<string>('DB_PORT', '5432'), 10),
        username: config.get<string>('DB_USER', 'synclog'),
        password: config.get<string>('DB_PASSWORD', 'synclog'),
        database: config.get<string>('DB_NAME', 'synclog'),
        autoLoadEntities: true,
        // Auto-sync schema from entities in dev; use migrations in production.
        synchronize: config.get<string>('DB_SYNC', 'true') === 'true',
      }),
    }),
    AuthModule,
    TeamsModule,
    NotificationsModule,
    RemindersModule,
    // Daily ensemble render (cron + ffmpeg) and the SNS feed/follow graph.
    EnsemblesModule,
    SocialModule,
  ],
})
export class AppModule {}
