# SyncLog — Backend (BE)

This directory holds the **backend** for SyncLog. It is currently empty; all
future server-side code lives here.

The frontend (Flutter app) expects the REST API described in the product spec
and wired in `FE/lib/data/datasources/team_remote_datasource.dart`:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET`  | `/api/v1/teams` | List the current user's 합주 팀 |
| `GET`  | `/api/v1/teams/{id}/stream` | One team's active tracks + `sync_offset_ms` + timeline |
| `POST` | `/api/v1/teams` | Create a team |
| `POST` | `/api/v1/teams/{id}/record` | Upload a take (multipart: `video`, `track_id`, `sync_offset_ms`, `member_id`, `note`) |

The frontend is **local-first**, so it runs without this backend. Once the server
is up, point the app at it:

```bash
flutter run --dart-define=USE_REMOTE=true --dart-define=API_BASE_URL=https://your-host
```

The JSON shapes the client (de)serializes are defined by the entity
`toJson` / `fromJson` methods under `FE/lib/domain/entities/`.
