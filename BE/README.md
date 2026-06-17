# SyncLog — Backend (BE)

REST API for the SyncLog app. **NestJS (TypeScript) + PostgreSQL + TypeORM**,
JWT auth. The JSON it speaks matches the Flutter client's entities 1:1
(`FE/lib/domain/entities/*.dart`), so the app can deserialize responses
unchanged.

## Stack

| Concern | Choice |
|---------|--------|
| Framework | NestJS 10 (Node 20, TypeScript) |
| Database | PostgreSQL 16 |
| ORM | TypeORM (auto-sync schema in dev) |
| Auth | JWT (Bearer), bcrypt password hashes |
| Uploads | Multer → local `uploads/`, served at `/uploads/*` |

## Run it

### Option A — Docker (recommended, no Node needed)

Brings up Postgres **and** the API; the schema is auto-created on boot.

```bash
cd BE
docker compose up --build
# API → http://localhost:3000/api/v1
```

Seed demo data (one-off, after the stack is up). `nest build` compiles the
seeder to `dist/`, and the container already has `DB_HOST=db` in its env:

```bash
docker compose exec api node dist/database/seed.js
```

> Demo login: **`demo@synclog.app` / `synclog1`** (seeds 3 example teams).

### Option B — Local Node toolchain

```bash
cd BE
cp .env.example .env          # adjust DB creds if needed
npm install
# Postgres must be reachable per .env (e.g. `docker compose up db`)
npm run start:dev             # watch mode → http://localhost:3000/api/v1
npm run seed                  # optional: demo account + 3 example teams
```

## API

Base path: `/api/v1`. All `teams` routes require `Authorization: Bearer <token>`.

### Auth

| Method | Path | Body | Returns |
|--------|------|------|---------|
| `POST` | `/auth/signup` | `{ name, email, password }` | `{ token, user }` |
| `POST` | `/auth/login`  | `{ email, password }` | `{ token, user }` |
| `GET`  | `/auth/me`     | — (Bearer) | `user` (Person) |

`user` is a **Person**: `{ id, name, initial, color, email }` (`color` is an
0xAARRGGBB int, matching `Color.toARGB32()` on the client).

### Teams

| Method | Path | Purpose |
|--------|------|---------|
| `GET`  | `/teams` | The current user's teams, newest first |
| `GET`  | `/teams/:id/stream` | One team (tracks + sync offsets + timeline) |
| `POST` | `/teams` | Create a team (reads `name`, `song`, `bpm`, `memberCount`/`tracks.length`) |
| `POST` | `/teams/:id/record` | Upload a take — `multipart/form-data` |

`/record` fields: `video` (file), `track_id`, `sync_offset_ms`, `member_id`,
`note`. The server stores the video, marks the slot **ready**, bumps the team
version, and appends a commit — the same logic the client runs locally
(`team_repository_impl.dart`), ported to `teams.service.ts`. The acting member
is taken from the token, not the `member_id` field.

All team/track/commit JSON exactly matches the client's `toJson`/`fromJson`.

## Configuration

See `.env.example`. Key vars: `DB_*`, `JWT_SECRET`, `PUBLIC_URL` (base URL used
to build `videoUrl`), `DB_SYNC` (auto-create schema; turn off + use migrations
in production).

## Database

The schema (5 tables: `users`, `teams`, `team_members`, `tracks`, `commits`) is
documented in **[`SCHEMA.md`](SCHEMA.md)**. Dev auto-creates it from the
entities; for production use migrations:

```bash
DB_SYNC=false npm run migration:generate -- src/database/migrations/Init
npm run migration:run
```

## Connecting the Flutter app

The app is **local-first** and ships with on-device mock auth, so it runs
without this server. It is also already **wired** to use this backend when
pointed at it — no code change needed:

- `AuthController` (remote mode) calls `POST /auth/signup` / `POST /auth/login`
  and caches the returned JWT.
- `HttpTeamRemoteDataSource` sends `Authorization: Bearer <token>` on every
  team request.

Both switch on automatically when `USE_REMOTE=true`. Launch against the API:

```bash
flutter run \
  --dart-define=USE_REMOTE=true \
  --dart-define=API_BASE_URL=http://localhost:3000
```

> Use a host the device can reach: `http://10.0.2.2:3000` for the Android
> emulator, or your machine's LAN IP for a physical device.

## Project layout

```
src/
  main.ts                 bootstrap (global prefix /api/v1, CORS, static uploads)
  app.module.ts           config + TypeORM wiring
  common/                 avatar.ts, sync.ts — ports of the FE utils (color, version)
  users/user.entity.ts
  auth/                   JWT signup/login/me (strategy, guard, @CurrentUser)
  teams/                  teams + tracks + commits (controller, service, entities)
    serializers.ts        entity → FE-compatible JSON
  database/               standalone DataSource + seed script
```
