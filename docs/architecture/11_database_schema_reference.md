# 11. Database Schema Reference
_Last Modified: 2026-09-21_

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

## Supabase Realtime
- **Chat**: Channel name `chat_messages_for_$userId`, listening to `INSERT` on `chat_messages` in `public` schema.
