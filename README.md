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
