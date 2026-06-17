# SyncLog (싱크로그)

An **async ensemble-recording app**. A team (합주 팀) picks one target song and a
fixed tempo; each member films their part to a metronome, micro-tunes how their
take sits against the beat, and stacks it onto a shared multitrack timeline that
grows like a Git history.

## Repository layout

This is a monorepo split into frontend and backend:

| Directory | Contents |
|-----------|----------|
| **[`FE/`](FE/README.md)** | Flutter app (frontend). All client code, assets, and platform projects. See `FE/README.md`. |
| **[`BE/`](BE/README.md)** | Backend (server). Currently empty; all future server-side code goes here. See `BE/README.md`. |

## Getting started

Frontend:

```bash
cd FE
flutter pub get
flutter run            # device / emulator
flutter run -d chrome  # web
```

Backend: see `BE/README.md` for the API contract the frontend expects. The app is
local-first, so the frontend runs fully without a backend until one is wired up.
