# Quest Engineering Handoff: Roadmap & Execution Guide (Phases 3–7)

_Author: Senior Architecture Auditor_  
_Last Modified: 2026-10-05_  
_Target Engineer: Jules & Quest Core Engineering Team_  
_Companion Docs: [AUDIT_2026-10-05.md](AUDIT_2026-10-05.md), [CODEBASE_DOCUMENTATION.md](../CODEBASE_DOCUMENTATION.md), [CHANGELOG.md](CHANGELOG.md)_

---

## 1. Executive Summary & Current State of the Codebase

### Completed Work Before Your Handover:
1. **Phase 1: Foundation Hardening & Identity**
   - Implemented strict 3-tier identity model: `AccessLevel.unauthenticated`, `AccessLevel.guest`, `AccessLevel.member`.
   - Native Google Sign-In with explicit intent separation (`GoogleIntent.signIn` vs `GoogleIntent.signUp`).
   - Unified single-authority routing in `app_router.dart` driven deterministically by auth session + profile state (eliminated competing splash timer).
   - Server-authoritative profile mutations in `user_repository.dart` with optimistic UI rollback on failure. Removed legacy `profiles.full_name` 400 bug.
   - Added username rules, formatting, and debounced availability check during onboarding.
   - Prepared security migration `supabase/migrations/20261005000000_foundation_security.sql`.
2. **Security & Credential Remediation (`.env`)**
   - Stripped all privileged secrets (`SUPABASE_SERVICE_ROLE_KEY`, `MUX_TOKEN_SECRET`, `CLOUDINARY_API_SECRET`, `IMAGEKIT_PRIVATE_KEY`) from client bundle and root `.env`.
   - Quarantined backend secrets to `supabase/.env.local` for local Edge Function execution.
   - Created server-side signing Edge Function `sign-media-upload/index.ts` to issue pre-signed Mux direct upload URLs, poll Mux asset readiness, and sign Cloudinary/ImageKit uploads.
   - Hardened `lib/core/env/env.dart` with compile-time `--dart-define` support and active memory purging of forbidden keys (`Env.sanitizeEnvironment()`).
3. **Phase 2: Home Dashboard & Feed Stabilization**
   - Removed sample video fallbacks from `feed_repository.dart`; feed now queries real rows from unified `videos` table (`video_type = 'feed'`) joined with `profiles(username, avatar_url)`.
   - Added honest empty state to `feed_screen.dart` with direct Call-to-Action to `/create`.
   - Added guest interaction gates (unauthenticated/guest users prompted to sign in when liking/commenting/sharing).
   - Removed bottom nav gesture traps in `main_shell.dart` (double-tap/swipe on Home icon).
   - Home Dashboard streamlined as the daily operating hub with real level/XP bars, live daily quests, upcoming events, and explicit `/feed` entry point.

---

## 2. Live Supabase Ground Truth (Schema Reality)

> [!IMPORTANT]
> **DO NOT ASSUME A TABLE EXISTS BASED ON MIGRATIONS OR CLIENT MODELS.**  
> The live Supabase instance (`ipvsbunseucoheycxpeg.supabase.co`) was directly probed using REST selects. Here is the verified reality:

| Table / RPC | Status in Live DB | Reality & Columns |
|---|---|---|
| `public.profiles` | **EXISTS** | `id`, `name`, `username`, `avatar_url`, `avatarUrl`, `bio`, `onboarding_completed`, `role`, `updated_at`, `currentXp`, `level`, `archetypes`, `joinedCommunityIds`, `rsvpdEventIds`. Note: `full_name` and `xp` DO NOT exist. |
| `public.videos` | **EXISTS** | Unified videos table: `id`, `user_id`, `video_type` ('feed','story',etc.), `video_url`, `thumbnail_url`, `mux_playback_id`, `mux_asset_id`, `title`, `description`, `like_count`, `comment_count`, `view_count`, `share_count`, `tags`, `community_id`, `event_id`, `quest_id`, `created_at`. |
| `public.feed_videos` | **EXISTS** | Renamed from `creator_videos` in migration `20260918000554`. Empty (0 rows). Prefer querying `videos` table. |
| `public.stories` | **EXISTS** | Stories table. |
| `public.daily_quests` | **EXISTS** | `id`, `userId`. Note: column is camelCase `userId`! |
| `public.events` | **EXISTS** | `id`, title, description, text date. Note: `starts_at` and `latitude` DO NOT exist in live DB. |
| `public.communities` | **EXISTS** | Communities table. |
| `public.community_posts`| **EXISTS** | Posts table for community boards. |
| `public.chat_rooms` | **EXISTS** | Chat rooms table (has RLS recursion bug on live, fixed in `20261005000000_foundation_security.sql`). |
| `public.chat_participants` | **EXISTS** | `roomId`, `userId` (camelCase). |
| `public.chat_messages` | **EXISTS** | Messages table. |
| `public.leaderboard` | **EXISTS** | Leaderboard view/table. |
| `public.user_trust_scores` | **EXISTS** | `user_id`, `score`, `level`. |
| `public.radar_nodes` | **EXISTS** | Node locations. |
| `public.stage_rooms` | **EXISTS** | Audio stage rooms. |
| `public.event_rsvps` | **MISSING (404)** | Currently attendee state is stored in `profiles.rsvpdEventIds` array. Needs migration. |
| `public.community_members` | **MISSING (404)** | Currently membership is in `profiles.joinedCommunityIds` array. Needs migration. |
| `public.notifications` | **MISSING (404)** | No notifications table exists yet. |
| `public.xp_events` / `achievements` / `challenges` | **MISSING (404)** | Progress lives in profile scalars and client storage. |
| RPC `check_username_available` | **DEFINED IN MIGRATION** | In `20261005000000_foundation_security.sql`. Must deploy migration. |
| RPC `award_xp` | **MISSING** | Needs migration. |

---

## 3. Phase 3: Create & Upload Experience

**Objective**: Make media creation, local compression, background upload, and post publishing rock solid with honest error handling and zero fake success toasts.

### Target Files:
- `lib/features/interaction/create/presentation/share_experience_screen.dart`
- `lib/features/interaction/create/presentation/camera_screen.dart`
- `lib/core/media/media_service_gateway.dart`
- `lib/core/media/media_compressor.dart`
- `supabase/functions/publish-experience/index.ts`

### Action Items for Jules:
1. **Camera Screen (`camera_screen.dart`)**:
   - Audit camera initialization and permission errors (`CameraException`).
   - If camera access is denied, show an explicit in-app permission banner with button to open system settings (`openAppSettings()`), not a silent black screen.
   - Handle aspect ratio constraints (standard 9:16 vertical video).
2. **Media Gateway Integration**:
   - `ShareExperienceScreen` currently calls `MediaServiceGateway.uploadVideo` or `uploadImage`.
   - Verify that `MediaServiceGateway` passes `onStatus` updates (`Compressing...`, `Requesting upload ticket...`, `Uploading to Mux...`, `Finalizing...`) through to the UI overlay.
   - If upload fails, show a retry dialog or snackbar with the specific failure cause; DO NOT navigate back to home pretending it published.
3. **Publishing Destination Alignment**:
   - `publish-experience` edge function inserts rows into `videos` table (`video_type`: `'feed'`, `'story'`, `'community'`).
   - Verify payload matches `supabase/functions/publish-experience/index.ts`:
     - `media_url`: string
     - `mux_playback_id`: string?
     - `mux_asset_id`: string?
     - `caption`: string
     - `destinations`: `['feed', 'story', 'community']`
     - `community_id`: string? (UUID)

---

## 4. Phase 4: Connect Hub & Navigation Restructure

**Objective**: Coalesce the sprawling, fragmented social navigation into a unified **Connect Hub**.

### Target Files:
- `lib/core/router/app_router.dart`
- `lib/core/shell/main_shell.dart`
- `lib/features/interaction/connect/presentation/connect_screen.dart`
- `lib/features/interaction/messaging/presentation/messages_screen.dart`
- `lib/features/society/communities/presentation/communities_screen.dart`
- `lib/features/society/events/presentation/events_screen.dart`
- `lib/features/society/radar/presentation/radar_screen.dart`

### Architectural Vision:
The bottom navigation bar has 5 core destinations:
1. **Home** (`/home`): Daily quest operating system, level progress, spotlights, quick actions.
2. **Explore** (`/explore`): Global discovery, trending media, tag browsing, search.
3. **Create** (`/create`): Camera, capture, upload overlay.
4. **Connect** (`/connect`): Unified social hub containing:
   - **Messages / Direct Chats** (top tab or primary sub-view)
   - **Communities & Guilds** (sub-view)
   - **Events & Gatherings** (sub-view)
   - **Proximity Radar** (sub-view with privacy warning)
5. **You / Profile** (`/profile`): Identity genome, settings, edit profile, user videos.

### Action Items for Jules:
1. **Fix Live Chat Recursion Bug**:
   - In live database, `chat_rooms` and `chat_participants` return **500 Infinite Recursion**.
   - Apply `supabase/migrations/20261005000000_foundation_security.sql` using `supabase db push`.
   - Remove `_generateTelegramDemoThreads` from `chat_repository.dart` once real chat loads.
2. **Connect Screen Sub-Tabs**:
   - Implement smooth top navigation / segmented controls in `connect_screen.dart` for:
     - `Chats` (Messages)
     - `Communities`
     - `Events`
     - `Radar`
   - Preserve scroll state between tab switches (`PageStorageKey` or `IndexedStack`).
3. **Guest Protection in Connect**:
   - Reading public events and communities is permitted for guests.
   - Sending chat messages, joining communities, or RSVPing must prompt `AccessLevel` modal to sign up.

---

## 5. Phase 5: Search & Discovery Backend Integration

**Objective**: Remove fake search mocks and connect global search to live Postgres tables.

### Target Files:
- `lib/features/interaction/explore/data/global_search_repository.dart`
- `lib/features/interaction/explore/presentation/explore_screen.dart`

### Action Items for Jules:
1. **Purge Mock Data in `global_search_repository.dart`**:
   - Delete `_getMockPeople()`, `_getMockCommunities()`, `_getMockEvents()`, `_getMockQuests()`.
2. **Connect Direct Supabase Searches**:
   - People: Query `profiles.select('id, username, name, avatar_url, bio').ilike('username', '%$query%')`.
   - Communities: Query `communities.select().ilike('name', '%$query%')`.
   - Events: Query `events.select().ilike('title', '%$query%')`.
   - Videos: Query `videos.select('*, profiles(username, avatar_url)').ilike('title', '%$query%')`.
3. **Implement Real Debounce**:
   - Debounce search inputs by 300ms using a timer or `rxdart` to avoid hammering Supabase on every keystroke.
4. **Clean Empty & Zero Results States**:
   - If query yields no matches, display: `"No results found for '$query'"`. Never fallback to fake mock items.

---

## 6. Phase 6: Relational Integrity & Schema Migrations

**Objective**: Transition from profile array storage (`rsvpdEventIds`, `joinedCommunityIds`) to proper relational database tables.

### Required Database Migrations (`supabase/migrations/`):
1. **Event RSVPs Table**:
   ```sql
   CREATE TABLE IF NOT EXISTS public.event_rsvps (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
     user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
     status TEXT NOT NULL DEFAULT 'going',
     created_at TIMESTAMPTZ DEFAULT now(),
     UNIQUE(event_id, user_id)
   );
   ALTER TABLE public.event_rsvps ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Public read RSVPs" ON public.event_rsvps FOR SELECT USING (true);
   CREATE POLICY "Members manage own RSVP" ON public.event_rsvps FOR ALL USING (auth.uid() = user_id);
   ```
2. **Community Members Table**:
   ```sql
   CREATE TABLE IF NOT EXISTS public.community_members (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     community_id UUID NOT NULL REFERENCES public.communities(id) ON DELETE CASCADE,
     user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
     role TEXT NOT NULL DEFAULT 'member',
     created_at TIMESTAMPTZ DEFAULT now(),
     UNIQUE(community_id, user_id)
   );
   ALTER TABLE public.community_members ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Public read memberships" ON public.community_members FOR SELECT USING (true);
   CREATE POLICY "Members manage own membership" ON public.community_members FOR ALL USING (auth.uid() = user_id);
   ```
3. **Notifications Table**:
   ```sql
   CREATE TABLE IF NOT EXISTS public.notifications (
     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
     user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
     type TEXT NOT NULL,
     title TEXT NOT NULL,
     body TEXT NOT NULL,
     data JSONB DEFAULT '{}',
     read BOOLEAN DEFAULT false,
     created_at TIMESTAMPTZ DEFAULT now()
   );
   ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Users read own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
   ```
4. **Server-Side XP Engine (`award_xp` RPC)**:
   - Client must not be trusted to mutate `profiles.currentXp` or `level`.
   - Provide atomic Postgres function: `award_xp(p_user_id UUID, p_amount INT, p_reason TEXT)` that increments XP and handles level-up thresholds.

---

## 7. Phase 7: Polish, Performance & Design Excellence

**Objective**: Make the interface tactile, responsive, accessible, and delightful.

### Guidelines from `DESIGN.md` and `ui-skills` (Baseline UI):
1. **Tactile Haptics**:
   - `HapticFeedback.lightImpact()` on tab switches, bookmarking, and pill selections.
   - `HapticFeedback.mediumImpact()` on primary actions (RSVP, Join Community, Publish Experience).
   - `HapticFeedback.selectionClick()` on scrolling carousels.
2. **Fluid Micro-Animations**:
   - Use `Curves.easeOutCubic` or spring animations for sheet presentations.
   - Duration: 150ms–250ms max. Never exceed 300ms for micro-interactions.
3. **Typography & Data Formatting**:
   - Use `FontFeature.tabularFigures()` for numbers (XP, counts, timer countdowns) to eliminate jitter.
   - Format timestamps with `timeago` package cleanly.
4. **Dark Mode & Contrast**:
   - Strictly adhere to `context.colors` from `app_colors_extension.dart`. Never hardcode raw hex values.
   - Ensure high contrast for text over video thumbnails (`Colors.black54` gradient overlay).

---

## 8. Verification & QA Commands for Jules

Always run these commands before submitting any turn:

```bash
# 1. Check for analysis errors and warnings (Must be ZERO):
flutter analyze

# 2. Run all unit and widget tests (Must be 100% PASS):
flutter test

# 3. Check git status to ensure no accidental files or secrets are staged:
git status --short
```

---
_End of Jules Handoff Guide. Refer back to this document at the start of each phase._
