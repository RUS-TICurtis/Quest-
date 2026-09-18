# Quest Database Schema Reference

_Last Modified: 2026-09-18_

This document is the **source of truth for all column naming conventions, caching decisions, and data-flow rules** in the Quest codebase. Every agent writing code that touches Supabase or local storage must read this document first.

---

## 1. Migration Eras & Naming Convention

Quest's database schema evolved across multiple migration files. Two distinct eras introduced different naming styles, and **both coexist in the current schema**:

| Era | Migration File | Naming Style | Example Tables |
|-----|---------------|--------------|---------------|
| Phase 3 | `20260805_initial_schema.sql` | Quoted `camelCase` | `stories`, `chat_rooms`, `chat_participants`, `chat_messages`, `profiles` (partial) |
| Phase 4 | `20260821_add_snake_case.sql` | `snake_case` | `profiles` (extension columns), `daily_quests`, `community_members` |
| Phase 5 | `20260826_media.sql` | `snake_case` | `stories.media_url`, `stories.mux_playback_id`, `stories.user_id` |
| Phase 6 | `20260828_avatar.sql` | Both — intentional | `profiles.avatarUrl` + `profiles.avatar_url` |
| Phase 7 | `20260918_feed.sql` | `snake_case` | `feed_videos`, `feed_rankings` (materialized view) |

---

## 2. Table-Level Column Reference

### `profiles`

| Column | Type | Naming Era | Notes |
|--------|------|-----------|-------|
| `id` | uuid | snake_case | FK to `auth.users` |
| `name` | text | Phase 3 camelCase origin | Quoted `"name"` in some migrations |
| `full_name` | text | Phase 4 snake_case | Alias — always write both `name` and `full_name` |
| `username` | text | Phase 4 snake_case | Lowercase, no `@` prefix |
| `bio` | text | Phase 4 snake_case | |
| `avatarUrl` | text | Phase 3 camelCase | Quoted column — write both `avatarUrl` and `avatar_url` |
| `avatar_url` | text | Phase 6 snake_case | See ARCHITECTURE DECISION below |
| `initials` | text | Phase 3 | Derived from first+last name initial |
| `level` | int | Phase 4 | |
| `currentXp` | int | Phase 3 camelCase | Quoted column |
| `xpToNextLevel` | int | Phase 3 camelCase | Quoted column |
| `streak` | int | Phase 3 | |
| `archetypes` | text[] | Phase 4 | |
| `badges` | text[] | Phase 4 | |

> **ARCHITECTURE DECISION — Avatar Dual Columns**
> `avatarUrl` (camelCase) and `avatar_url` (snake_case) both exist and **must always be written simultaneously**. The `update-profile` Edge Function already does this. Direct upserts (fallback path in `user_repository.dart`) must also write both. This is the safest strategy to ensure both legacy consumers (camelCase reads) and new consumers (snake_case reads) see current data.

### `stories`

| Column | Type | Naming Era | Notes |
|--------|------|-----------|-------|
| `id` | uuid | — | |
| `"authorName"` | text | Phase 3 camelCase | **Quoted** — use exactly `'authorName'` in queries |
| `"communityName"` | text | Phase 3 camelCase | **Quoted** |
| `"isSeen"` | bool | Phase 3 camelCase | **Quoted** |
| `"createdAt"` | timestamptz | Phase 3 camelCase | **Quoted** — use `'createdAt'` in `order()` and `toSupabase()` |
| `"authorAvatar"` | text | Phase 3 camelCase | **Quoted** |
| `caption` | text | Phase 3 | |
| `media_url` | text | Phase 5 snake_case | Added in 20260826 migration |
| `mux_playback_id` | text | Phase 5 snake_case | |
| `user_id` | uuid | Phase 5 snake_case | FK to `auth.users` |
| `"timeAgo"` | text | Phase 3 camelCase | Denormalized display string |

### `chat_rooms`

| Column | Type | Naming Era | Notes |
|--------|------|-----------|-------|
| `id` | uuid | — | |
| `"isGroup"` | bool | Phase 3 camelCase | **Quoted** |
| `"lastMessageText"` | text | Phase 3 camelCase | **Quoted** |
| `"lastMessageTime"` | text | Phase 3 camelCase | **Quoted** |

### `chat_participants`

| Column | Type | Naming Era | Notes |
|--------|------|-----------|-------|
| `"roomId"` | uuid | Phase 3 camelCase | **Quoted** |
| `"userId"` | uuid | Phase 3 camelCase | **Quoted** |
| `"lastReadAt"` | timestamptz | Phase 3 camelCase | **Quoted** — used for unread count |

### `chat_messages`

| Column | Type | Naming Era | Notes |
|--------|------|-----------|-------|
| `"roomId"` | uuid | Phase 3 camelCase | **Quoted** |
| `"senderId"` | uuid | Phase 3 camelCase | **Quoted** |
| `"createdAt"` | timestamptz | Phase 3 camelCase | **Quoted** |
| `content` | text | Phase 3 | |
| `"isDeleted"` | bool | Phase 3 camelCase | **Quoted** |

### `feed_videos`

| Column | Type | Naming Era | Notes |
|--------|------|-----------|-------|
| `id` | uuid | — | |
| `video_url` | text | Phase 7 snake_case | |
| `thumbnail_url` | text | Phase 7 snake_case | |
| `title` | text | Phase 7 snake_case | |
| `description` | text | Phase 7 snake_case | |
| `view_count` | int | Phase 7 snake_case | |
| `like_count` | int | Phase 7 snake_case | |
| `comment_count` | int | Phase 7 snake_case | |
| `share_count` | int | Phase 7 snake_case | |
| `creator_id` | uuid | Phase 7 snake_case | FK to `profiles.id` |
| `engagement_score` | float | Phase 7 snake_case | |
| `duration_seconds` | int | Phase 7 snake_case | |
| `created_at` | timestamptz | Phase 7 snake_case | |

### `feed_rankings` (materialized view)

Backed by `feed_videos`. Used by the `get-feed` Edge Function. See note below.

---

## 3. Edge Function Notes

### `get-feed`
- Calls `get_edge_feed` RPC (or queries `feed_rankings` materialized view)
- Returns `videos[]` shaped from `feed_videos` columns
- Accepts `seen_ids[]` for deduplication
- **NOT** the same as `interact-video` — see below

### `interact-video`
- Targets the **`videos`** table (NOT `feed_videos` or `feed_rankings`)
- Used for `like`, `comment`, `view` actions
- ⚠️ **Known mismatch:** If feed is backed by `feed_videos`, like counts from `interact-video` may not reflect in feed until `feed_rankings` is refreshed. Investigate `feed_rankings` view definition before fixing.

### `update-profile`
- Writes both `avatarUrl` and `avatar_url` columns simultaneously (intentional dual write)
- Direct DB upsert fallback in `user_repository.dart` must also write both

---

## 4. Caching Layer Assignments

| Data Type | Cache Layer | Box Name / Service | TTL |
|-----------|-------------|-------------------|-----|
| Settings (bool/string/int) | SharedPreferences (`LocalStorageService`) | N/A | Indefinite |
| Profile (scalar) | SharedPreferences | `profile_*` keys | Session |
| Chat rooms | Hive Box | `chat_rooms` | Until evicted |
| Chat messages | Hive Box | `chat_messages` | Until evicted |
| Feed videos | Hive Box | `feed_video_cache` | No TTL (LRU by cachedAt) |
| Member profiles | Hive Box | `profile_cache` | 15 minutes (`isStale`) |
| Stories | Hive Box | `story_cache` | 24 hours (`isExpired`) |

### Caching Tool Decision

> **Isar was evaluated and rejected.** `isar 3.1.0+1` only supports Dart `<3.0.0`. `isar_community` had no stable pub.dev release. The existing Hive infrastructure was extended instead.
> If a Dart-3-compatible Isar or ObjectBox release becomes stable, consider migrating the `feed_video_cache` and `profile_cache` boxes for indexed queries.

---

## 5. Realtime Channels

| Channel Name | Table | Event | Purpose |
|-------------|-------|-------|---------|
| `chat_messages_for_{userId}` | `chat_messages` | INSERT | Live message delivery in `ConnectScreen` |

---

## 6. Agent Rules for Writing DB Code

1. **Always check this document** before writing a column name
2. **camelCase tables/columns**: Use single-quoted strings: `'authorName'`, `'createdAt'`, `'isSeen'`
3. **snake_case tables/columns**: Standard strings: `'video_url'`, `'creator_id'`
4. **Profile writes**: Always write `name` AND `full_name` together; `avatarUrl` AND `avatar_url` together
5. **Stories inserts**: Use `'createdAt'` (NOT `'created_at'`) in `toSupabase()`
6. **Feed interactions**: `interact-video` hits the `videos` table. `get-feed` hits `feed_rankings`. They are separate.
7. **New Hive models**: Use hand-written TypeAdapters (see `CachedFeedVideo`, `LocalChatRoom`). Do NOT add `hive_generator` — it conflicts with `build_runner ^2.15.1`.
