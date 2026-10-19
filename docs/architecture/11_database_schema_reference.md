# 11. Database Schema Reference
_Last Modified: 2026-10-19_

## The Schema Rule
When interacting with the database from Dart or Edge Functions, **only use what has already been created in the Supabase schema migrations**. Supabase accepts what is defined in its tables. Our schemas feature a mix of `camelCase` (e.g. `createdAt`) and `snake_case` (e.g. `avatar_url`). Do not attempt to enforce a single naming convention in Dart; use the exact column names as defined in the DB.

## Column Standardization: `avatar_url`
Historically, `profiles` had both `avatarUrl` and `avatar_url`. 
**Decision:** We standardize strictly on **`avatar_url`** in Dart when reading/writing from `profiles` because this matches the expectation of the Supabase edge functions (e.g. `get-feed`, `like-video`, `update-profile`). Do not use `avatarUrl` in Supabase inserts/updates.

## Caching Layer Assignment
- **SharedPreferences** (`local_storage_service.dart`): Small scalar settings (profile basics, UI preferences).
- **Hive** (`local_database_service.dart`): All structured offline caching. We use Hive `TypeAdapter`s for:
  - Chat rooms list (`chatRoomsBox`) - Until Realtime update
  - Chat messages (`chatMessagesBox`) - Until read/acked
  - Feed videos (`feedVideosBox`) - Session TTL, offline feed + seen tracking
  - Member profiles (`memberProfilesBox`) - 15 min TTL, stale-while-revalidate
  - Stories (`storiesBox`) - 24h TTL, mirrors server pg_cron cleanup
- **cached_network_image**: Network images (avatars, thumbnails). Disk cache.

## Edge Functions
- `get-feed`: Takes `seed`, `cursor`, `limit`, `seen_ids`, `recent_genres`. Returns feed videos.
- `interact-video`: Takes `video_id`, `action`. Increments counts on the `videos` table.
- `update-profile`: Takes `username`, `full_name`, `avatar_url`, `bio`.
- `stage-token`: Takes `stage_id`, `role`, `uid`. Authenticates caller JWT and returns cryptographically signed RTC room tokens.

## Supabase Realtime
- **Chat**: Channel name `chat_messages_for_$userId`, listening to `INSERT` on `chat_messages` in `public` schema.
- **Stage (Audio Rooms)**: Broadcast channel `stage_$stageId` for `stage_reaction`, `stage_hand_raise`, and `stage_speaker_promotion`.

---
## Foundation security migration (added 2026-10-05)
_Last Modified: 2026-10-05_

`20261005000000_foundation_security.sql`: own-row profile RLS, `protect_profile_columns` trigger (level/currentXp/xpToNextLevel/streak/badges/role/creator_status/ban flags are service-role only), unique `lower(username)` index, `profiles_username_format` CHECK (`^[a-z0-9_]{3,30}$`, NOT VALID), RPC `check_username_available(text)`, `is_guest()`, `is_chat_participant(uuid)` (fixes recursive chat policies). Live DB has NO `profiles.full_name` - never write it. Missing tables: event_rsvps, community_members, notifications, xp_events, achievements, challenges, places, presences.

---
## Beacons Schema & Spontaneous Fellowship (added 2026-10-17)
_Last Modified: 2026-10-17_

`20261017000000_beacons_schema.sql`:
- **Table**: `public.beacons`
  - `id`: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
  - `creator_id`: `UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE`
  - `creator_name`: `TEXT NOT NULL`
  - `creator_avatar`: `TEXT NOT NULL DEFAULT ''`
  - `title`: `TEXT NOT NULL`
  - `description`: `TEXT DEFAULT ''`
  - `hub_id`: `TEXT NOT NULL`
  - `hub_name`: `TEXT NOT NULL`
  - `created_at`: `TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())`
  - `expires_at`: `TIMESTAMPTZ NOT NULL` (1–4 hour ephemeral TTL)
  - `attendee_ids`: `UUID[] NOT NULL DEFAULT '{}'`
  - `attendee_avatars`: `TEXT[] NOT NULL DEFAULT '{}'`
  - `xp_reward`: `INTEGER NOT NULL DEFAULT 50`
  - `angle_ratio`: `DOUBLE PRECISION NOT NULL DEFAULT 0.35`
  - `radius_ratio`: `DOUBLE PRECISION NOT NULL DEFAULT 0.55`
- **RLS Policies**:
  - `Anyone can view active beacons`: `SELECT` allowed where `expires_at > timezone('utc'::text, now())`
  - `Authenticated users can create beacons`: `INSERT` allowed with `auth.uid() = creator_id`
  - `Authenticated users can update attendee lists`: `UPDATE` allowed for joining active beacons
  - `Creators can delete their own beacons`: `DELETE` allowed with `auth.uid() = creator_id`
- **Automation**: `pg_cron` hourly scheduled job (`cleanup_expired_beacons`) deletes beacons past their `expires_at` timestamp.

