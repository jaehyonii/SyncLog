# SyncLog — Database schema

PostgreSQL, owned by the backend via TypeORM entities under `src/`. In dev the
schema is created automatically from those entities (`DB_SYNC=true`); in
production, turn sync off and apply migrations (see below). This file is the
human-readable reference — the entities are the source of truth.

## Tables

### `users` — accounts (`src/users/user.entity.ts`)

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `name` | varchar | |
| `email` | varchar | **unique** |
| `passwordHash` | varchar | bcrypt hash; never returned to clients |
| `initial` | varchar | first grapheme of name (avatar) |
| `color` | bigint | 0xAARRGGBB int (bigint — alpha byte exceeds signed int range) |
| `createdAt` | timestamptz | default now |

Serialized to clients as a **Person** `{ id, name, initial, color, email }`
(never the hash).

### `teams` — ensemble teams (`src/teams/entities/team.entity.ts`)

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `name` | varchar | |
| `song` | varchar | default `''` |
| `artist` | varchar | default `''` |
| `bpm` | int | default 90 |
| `coverColor` | bigint | 0xAARRGGBB int |
| `ownerId` | uuid | the creator (also present in `team_members`) |
| `createdAt` | timestamptz | default now; list order (newest first) |

### `team_members` — roster (`src/teams/entities/team-member.entity.ts`)

| Column | Type | Notes |
|--------|------|-------|
| `teamId` | uuid | PK (composite), FK → `teams.id` (CASCADE) |
| `userId` | uuid | PK (composite), FK → `users.id` (CASCADE) |
| `joinedAt` | timestamptz | default now; roster order (creator first) |

Explicit join table so member **order** is stable.

### `tracks` — multitrack slots (`src/teams/entities/track.entity.ts`)

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `teamId` | uuid | FK → `teams.id` (CASCADE) |
| `part` | varchar | e.g. `Drums` |
| `partKo` | varchar | e.g. `드럼` |
| `instrument` | varchar | glyph key; default `audio-lines` |
| `status` | varchar | `open` \| `ready`; default `open` |
| `memberId` | uuid? | FK → `users.id` (SET NULL); null for open slots |
| `syncOffsetMs` | int | default 0 |
| `videoUrl` | varchar? | `${PUBLIC_URL}/uploads/<file>` once recorded |
| `note` | varchar? | |
| `position` | int | slot ordering within the team |

### `commits` — practice timeline (`src/teams/entities/commit.entity.ts`)

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `teamId` | uuid | FK → `teams.id` (CASCADE) |
| `memberId` | uuid | FK → `users.id` (CASCADE) |
| `version` | varchar | `vMAJOR.MINOR`, bumped per take |
| `note` | text | one-line message |
| `part` | varchar? | the part this commit touched |
| `createdAt` | timestamptz | default now; timeline order (newest first) |

### `notifications` — activity feed (`src/notifications/entities/notification.entity.ts`)

| Column | Type | Notes |
|--------|------|-------|
| `id` | uuid | PK |
| `userId` | uuid | recipient (indexed); the feed is "my notifications" |
| `actorId` | uuid | FK → `users.id` (CASCADE); who triggered it |
| `teamId` | uuid? | the related team (nullable) |
| `teamName` | varchar | denormalized so it survives team deletion |
| `type` | varchar | `join` \| `take` |
| `title` | varchar | one-line headline |
| `body` | text | detail line |
| `read` | boolean | default false |
| `createdAt` | timestamptz | default now; feed order (newest first) |

Rows are created in `TeamsService` when someone joins a team or records a take,
one per other member. Serialized to clients as `{ id, type, title, body, teamId,
teamName, actor (Person), read, createdAt }`.

## Relationships

```
users 1───* team_members *───1 teams
users 1───* tracks  (member, nullable)   teams 1───* tracks
users 1───* commits                      teams 1───* commits
users 1───* notifications (recipient + actor)
```

Deleting a team cascades to its members, tracks, and commits. Deleting a user
cascades their roster rows and commits; their tracks have `memberId` set to null
(the slot reverts toward open).

## Migrations

Dev uses `DB_SYNC=true` (auto-create from entities). For production:

```bash
# 1) turn auto-sync off
export DB_SYNC=false
# 2) generate a migration by diffing entities against the live DB
npm run migration:generate -- src/database/migrations/Init
# 3) apply / roll back
npm run migration:run
npm run migration:revert
```

Migrations live in `src/database/migrations/` and are tracked in the
`migrations` table. Generation requires a reachable database (it diffs the
current schema), so it is run against your dev/staging DB, then committed.
