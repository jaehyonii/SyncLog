import 'reflect-metadata';
import { join } from 'node:path';
import { DataSource } from 'typeorm';
import { CommitEntity } from '../teams/entities/commit.entity';
import { TeamMemberEntity } from '../teams/entities/team-member.entity';
import { TeamEntity } from '../teams/entities/team.entity';
import { TrackEntity } from '../teams/entities/track.entity';
import { UserEntity } from '../users/user.entity';

/**
 * A standalone TypeORM DataSource (no Nest DI) used by scripts (the seeder) and
 * the TypeORM CLI (migrations). Reads the same env vars as the app; defaults
 * match docker-compose so `npm run seed` / migrations work against a
 * `docker compose up` database out of the box.
 */
export function buildDataSource(): DataSource {
  return new DataSource({
    type: 'postgres',
    host: process.env.DB_HOST ?? 'localhost',
    port: parseInt(process.env.DB_PORT ?? '5432', 10),
    username: process.env.DB_USER ?? 'synclog',
    password: process.env.DB_PASSWORD ?? 'synclog',
    database: process.env.DB_NAME ?? 'synclog',
    entities: [
      UserEntity,
      TeamEntity,
      TeamMemberEntity,
      TrackEntity,
      CommitEntity,
    ],
    // Resolves .ts under ts-node (CLI) and .js when running compiled output.
    migrations: [join(__dirname, 'migrations', '*.{ts,js}')],
    migrationsTableName: 'migrations',
    synchronize: (process.env.DB_SYNC ?? 'true') === 'true',
  });
}

// Default-exported instance for the TypeORM CLI: `-d src/database/data-source.ts`.
export default buildDataSource();
