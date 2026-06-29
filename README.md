# SyncLog (싱크로그)

An **async ensemble-recording app**. A team (합주 팀) picks one target song and a
fixed tempo; each member films their part to a metronome, micro-tunes how their
take sits against the beat, and stacks it onto a shared multitrack timeline that
grows like a Git history.

## Repository layout

This is a monorepo split into three tiers — frontend, backend, and database:

| Directory | Contents |
|-----------|----------|
| **[`FE/`](FE/README.md)** | Flutter app (frontend). All client code, assets, and platform projects. See `FE/README.md`. |
| **[`BE/`](BE/README.md)** | Backend (server). NestJS + PostgreSQL REST API; JSON matches the FE entities 1:1. See `BE/README.md`. |

The database (PostgreSQL) is the third tier; it runs alongside the API via
`BE/docker-compose.yml`.

## Getting started

Frontend:

```bash
cd FE
flutter pub get
flutter run            # device / emulator
flutter run -d chrome  # web
```

Backend + database:

```bash
cd BE
docker compose up --build   # PostgreSQL + the NestJS API at :3000/api/v1
```

See `BE/README.md` for the API, env vars, and how to point the app at it. The
app is local-first, so the frontend also runs fully without the backend.

## Public deployment (HTTPS)

The backend can be served on a public domain with automatic TLS via a built-in
Caddy reverse proxy (Let's Encrypt). On a host whose domain resolves to it, with
ports `80`/`443` open:

```bash
cd BE
cp .env.example .env        # set CADDY_DOMAIN, PUBLIC_URL (https), JWT_SECRET
docker compose --profile proxy up -d --build
# API → https://<your-domain>/api/v1
```

The app then connects from any network (no `adb reverse`, video playback over
HTTPS):

```bash
cd FE
flutter run --dart-define=USE_REMOTE=true \
            --dart-define=API_BASE_URL=https://<your-domain>
```

By default the API (`3000`) and Postgres (`5432`) ports bind to loopback only;
Caddy is the sole public entry point. See `BE/README.md` for details and
operating commands.
