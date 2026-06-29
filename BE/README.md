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

### Public HTTPS — Caddy reverse proxy

To serve the API on a public domain with automatic TLS (real devices on any
network, no cleartext issues), front it with Caddy. It obtains and renews a
Let's Encrypt certificate for your domain and proxies to the `api` container.

Prerequisites: a domain pointing at this host (e.g. `kimsvr7.ddns.net`) and
ports **80 + 443** reachable from the internet (for the ACME challenge).

```bash
cd BE
cp .env.example .env
# in .env set (the .env file is gitignored — secrets stay local):
#   CADDY_DOMAIN=kimsvr7.ddns.net
#   PUBLIC_URL=https://kimsvr7.ddns.net
#   JWT_SECRET=<long random string, e.g. `openssl rand -hex 48`>
docker compose --profile proxy up -d --build
# API → https://kimsvr7.ddns.net/api/v1
```

The Flutter client then points at it (works from any network — no `adb reverse`,
and HTTPS means no cleartext-video workaround needed):

```bash
flutter run --dart-define=USE_REMOTE=true \
            --dart-define=API_BASE_URL=https://kimsvr7.ddns.net
```

> `PUBLIC_URL` must match the public HTTPS address so generated `videoUrl`s are
> reachable from clients. Certificates persist in the `caddy_data` volume and
> renew automatically.

**Hardening (defaults).** The published API (`3000`) and Postgres (`5432`) ports
bind to `127.0.0.1` only, so neither is exposed to the internet — Caddy reaches
the API over the internal Docker network, and `80`/`443` are the only public
ports. `localhost` dev and `adb reverse` still work. To expose them on the LAN,
set `API_BIND=0.0.0.0` / `DB_BIND=0.0.0.0` in `.env`. Always set a strong
`JWT_SECRET` for any public deployment (rotating it invalidates existing tokens).

**Operating the proxy stack** (always include `--profile proxy` so Caddy starts):

```bash
docker compose --profile proxy up -d --build   # start / apply changes
docker compose --profile proxy ps              # status
docker compose --profile proxy logs -f caddy   # cert + access logs
docker compose --profile proxy down            # stop (keeps data + certs)
```

## API

Base path: `/api/v1`. All `teams` routes require `Authorization: Bearer <token>`.

### Auth

| Method | Path | Body | Returns |
|--------|------|------|---------|
| `POST`  | `/auth/signup` | `{ name, email, password }` | `{ token, user }` |
| `POST`  | `/auth/login`  | `{ email, password }` | `{ token, user }` |
| `GET`   | `/auth/me`     | — (Bearer) | `user` (Person) |
| `PATCH` | `/auth/me`     | `{ name?, email?, password? }` (Bearer) | `user` (Person) |

`user` is a **Person**: `{ id, name, initial, color, email }` (`color` is an
0xAARRGGBB int, matching `Color.toARGB32()` on the client). `PATCH /auth/me`
edits only the supplied fields (renaming also refreshes the initials avatar; a
new email is checked for clashes); the existing token stays valid.

### Teams

| Method | Path | Purpose |
|--------|------|---------|
| `GET`  | `/teams` | The current user's teams, newest first |
| `GET`  | `/teams/discover` | Other teams' public takes the user isn't in (invite codes stripped) |
| `GET`  | `/teams/:id/stream` | One team (tracks + sync offsets + timeline) |
| `POST` | `/teams` | Create a team (reads `name`, `song`, `bpm`, `memberCount`/`tracks.length`) |
| `POST` | `/teams/join` | Join a team by its invite code (`{ code }`) |
| `POST` | `/teams/:id/record` | Upload a take — `multipart/form-data` |

`/record` fields: `video` (file), `track_id`, `sync_offset_ms`, `member_id`,
`note`. The server stores the video, marks the slot **ready**, bumps the team
version, and appends a commit — the same logic the client runs locally
(`team_repository_impl.dart`), ported to `teams.service.ts`. The acting member
is taken from the token, not the `member_id` field.

All team/track/commit JSON exactly matches the client's `toJson`/`fromJson`.

### Notifications

| Method | Path | Purpose |
|--------|------|---------|
| `GET`  | `/notifications` | The user's activity feed, newest first |
| `POST` | `/notifications/read` | Mark all read; returns the refreshed feed |

A notification is fanned out to a team's other members when someone **joins**
the team or **records** a take. A scheduled **reminder** is sent to a part owner
who hasn't uploaded their part that day. Shape: `{ id, type
('join'|'take'|'reminder'), title, body, teamId, teamName, actor (Person), read,
createdAt }`.

### Scheduled reminders

A cron job (`@nestjs/schedule`) runs daily at **17:00** and **23:00** server time
and nudges every part owner whose part has no take today. The api container runs
as `Asia/Seoul` (`TZ` in docker-compose), so these fire at KST — the same zone
the one-upload-per-day boundary uses. Re-fires within an hour are de-duplicated.

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/reminders/run` | Run the "haven't uploaded today" sweep now (returns `{ sent }`) |

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
