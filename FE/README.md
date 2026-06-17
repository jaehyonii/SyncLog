# SyncLog (싱크로그)

An **async ensemble-recording app**, built in Flutter. A team (합주 팀) picks one
target song and a fixed tempo; each member films their part **to a metronome**,
micro-tunes how their take sits against the beat, and stacks it onto a shared
**multitrack timeline** that grows like a Git history.

> Core loop: **합주 팀 → 합주 히스토리 → 레코딩 스튜디오 → 싱크 조절 → 업데이트**

A production-grade implementation of the four core screens from the SyncLog
Claude Design handoff, recreating its visual system — a warm off-white "score
sheet" for the chrome, a near-black stage for camera/video, and one signature
**record-red** that only ever means live / record / active beat — on a layered,
local-first architecture.

## Screens

1. **Home — 합주 팀** — team cards (cover · target song · member stack · `ready/total · BPM`)
   with explicit loading / error / empty states. The `+` FAB opens a create-team
   sheet (name · 연습할 곡 · 팀원 수 · manager-set BPM · invite link); ☰ opens the
   left drawer. **Every team opens** into its own detail flow.
2. **Ensemble Detail & History** — a multitrack grid on the dark stage with a
   scrubber + transport (synced playback delays each track by its `sync_offset_ms`),
   and a Git-style practice timeline. Empty teams show open slots and a hint;
   the sticky CTA records into an open slot.
3. **Recording Studio** — a real camera preview when available (placeholder
   otherwise), a read-only BPM chip, a metronome that stays idle until recording
   begins, a 3·2·1·Start! count-in, record→stop, and ↺ reset.
4. **Micro-Sync Editor** — take preview, waveform, a live `±0.0Xs` slider (green
   **In sync** near zero), and an optional practice note. 이 로그로 업데이트 uploads
   through the repository, fills the slot and appends a versioned commit.

## Architecture

Layered, with dependencies pointing inward (presentation → domain ← data):

```
lib/
  config.dart                  AppConfig (API base URL, USE_REMOTE) via --dart-define
  main.dart                    composition root: config → datasources → repo → state
  app.dart                     MaterialApp.router + providers
  router.dart                  go_router routes (Home → Detail → Record → Sync)
  domain/
    entities/                  Person · Track · Commit · Team · RecordedTake (+ JSON)
    repositories/              TeamRepository (interface)
  data/
    datasources/               seed · local (SharedPreferences) · remote (REST, spec endpoints)
    repositories/              TeamRepositoryImpl (local-first, remote best-effort)
  services/                    Session, RecordingService, MultiTrackPlayer,
                               PermissionService, MetronomeAudio — each an interface
                               with a real impl (mobile) and a fake (web/desktop/tests)
  controllers/                 TeamsController · TeamDetailController · RecordingController
  theme/ · util/ · widgets/    tokens, helpers, reusable primitives
```

**Data — local-first (`로컬 우선`).** The on-device store (`SharedPreferences`) is
the source of truth, seeded on first run. The repository is wired to the spec's
REST API (`GET /api/v1/teams`, `GET /api/v1/teams/{id}/stream`,
`POST /api/v1/teams`, `POST /api/v1/teams/{id}/record` multipart) behind
`TeamRemoteDataSource`; it stays off until a server is configured, then is
consulted best-effort with local fallback. Flip it on with
`--dart-define=USE_REMOTE=true --dart-define=API_BASE_URL=…`.

**Devices — abstraction + default impl (`추상화 계층`).** Camera capture, multitrack
playback, permissions and metronome audio are interfaces. On Android/iOS the real
implementations run (`camera`, `video_player`, `permission_handler`); on
web/desktop/tests, fakes keep the full flow working — so the app builds and runs
everywhere and is fully functional on a real device.

## Running

```bash
flutter pub get
flutter run                # device / emulator (real camera on Android/iOS)
flutter run -d chrome      # web (fake capture/playback)

# Point at a live backend:
flutter run --dart-define=USE_REMOTE=true --dart-define=API_BASE_URL=https://api.synclog.app
```

## Testing

```bash
flutter analyze            # no issues
flutter test               # repository (seed/create/upload/persist) + boot smoke test
```

## Notes & extension points

- **Type.** Brand face is Spoqa Han Sans Neo (woff2 in the design bundle); this
  build uses Noto Sans KR (closest Google Fonts match) + JetBrains Mono for
  numerics via `google_fonts`. Self-host Spoqa for production.
- **Icons.** Lucide → Material mapping in `lib/theme/icons.dart` (Lucide is itself
  a stand-in for the app's real Flutter glyph set).
- **Local-file playback** of a freshly recorded take and **real network multitrack
  sync** are implemented in `services/playback_service.dart`; seed takes are dark
  placeholders, so simulated playback runs until real `videoUrl`s exist.
- **Metronome audio** is a silent hook (`services/metronome_audio.dart`) — plug in
  an audio plugin for the click.
- **iOS:** scaffold with `flutter create --platforms=ios .` and add camera/mic
  `NSCameraUsageDescription` / `NSMicrophoneUsageDescription` to `Info.plist`.
  Android camera/mic permissions are already declared in the manifest.
