# Changelog

_Last Modified: 2026-10-06_

## 2026-10-06 — Phases 4 to 7 Stabilization (Connect Hub, Search, Participation Engine, Truthful Presence)

### Phase 4: Connect Hub & Navigation Restructure
- **Purged Mock Threads**: Deleted `_generateTelegramDemoThreads()` and in-memory demo broadcast streams in `lib/features/interaction/messaging/data/chat_repository.dart`. New and guest accounts now yield an honest empty list `[]` instead of 10+ fake conversations.
- **Baseline-UI Empty State**: Upgraded `lib/features/interaction/messaging/presentation/messages_screen.dart` with an accessible empty state adhering to `ibelick/baseline-ui`, featuring an explicit "Find People" action button routing to `/connect/user_discovery` and unified theme colors (`context.colors`).
- **Unified Connect Hub**: Rebuilt `lib/features/interaction/connect/presentation/connect_screen.dart` as the central Social Hub with 4 primary tabs: **Messages** (with live unread badge), **Communities**, **Events**, and **Radar**. Added support for deep-linking via query parameters (`/connect?tab=communities`, etc.).
- **Shell Navigation Hardening**: Updated `lib/core/router/app_router.dart` to route legacy top-level `/communities`, `/events`, and `/radar` into the Connect Hub within `MainShell`, preserving the persistent bottom navigation bar while keeping `/communities/:id` and `/events/:id` detail routes intact.

### Phase 5: Global Search & Explore Stabilization
- **Purged Search Mocks**: Completely eliminated `_getMockUsers()`, `_getMockQuests()`, `_getMockEvents()`, `_getMockCommunities()`, and `_getFallbackSearchResults()` from `lib/features/interaction/explore/data/global_search_repository.dart`.
- **Honest Empty Search Results**: Added `GlobalSearchResults.empty()`. Searches with no matches return empty lists without silently falling back to fake seed users or events.
- **Verified Explore & Search UI**: Verified that `user_search_screen.dart` displays explicit empty state feedback ("No matches found for '[query]'") across all tabs without throwing exceptions.

### Phase 6: Participation Wiring (Backend Engine Integration)
- **Supabase Participation Methods**: Added `joinCommunity`, `leaveCommunity`, `rsvpEvent`, `cancelRsvpEvent`, and `awardXp` to `UserRepository` and implemented them in `SupabaseUserRepository` targeting `community_members`, `event_rsvps`, and `award_xp` RPC.
- **Persistent Membership & RSVP State**: Updated `getUser` in `user_repository.dart` to fetch real community memberships and event RSVPs in parallel on profile load.
- **Optimistic State & Rollback**: Wired `toggleJoinCommunity` and `toggleRsvpEvent` in `user_provider.dart` to execute backend database operations, award server-side XP, and roll back state on network or constraint errors.
- **UI Interaction & UTF-8 Polish**: Fixed corrupted UTF-8 checkmark characters in `community_detail_screen.dart` and `event_detail_screen.dart`, eliminated accidental double XP awarding on RSVP, and added error snackbar alerts on failure.

### Phase 7: Truthful Presence & Final Codebase Polish
- **Real Radar Members**: Replaced hardcoded mock radar members ("Jordan Reed", "Maya Lin") in `lib/features/world/radar/data/radar_repository.dart` with genuine profiles queried from Supabase.
- **Truthful Radar HUD**: Updated `lib/features/world/radar/presentation/radar_screen.dart` to display "0 Active" and an honest empty radar state ("No builders active on radar right now") when no nearby creators are detected.
- **Automated Test Suite**: Created `test/phase4_to_7_stabilization_test.dart` validating empty search models, JSON parsing with trust scores, hub locations, and empty radar states. All 14 tests in the test suite pass with 100% success.
- **Analysis Verification**: `flutter analyze` completed with **0 warnings, 0 errors**.

### 2026-10-05
* **Compliance:**
  * Installed App Store / Google Play Compliance Skill playbook securely.
  * Generated initial compliance audit in `docs/COMPLIANCE.md`.

## 2026-10-05 — Polish

* **UX Polish:**
  * Cleaned up haptic feedback across radar, community, and event screens to remove double-firing of light impacts.

## 2026-10-05 — Advanced Participation & Relational Integrity

* **Advanced Participation & Relational Integrity:**
  * Created migrations (`event_rsvps`, `community_members`, `notifications`) to migrate from arrays in `profiles` to properly normalized tables.
  * Setup `award_xp` RPC for secure server-side XP scaling.
  * Verified RLS policies protect events and community memberships correctly.

## 2026-10-05 — Foundation stabilization (audit Phase 1)

**Why:** audit found broken profile persistence, guest treated as member, two competing navigation authorities, indistinguishable Google sign-in/up, and open profile RLS. See [AUDIT_2026-10-05.md](AUDIT_2026-10-05.md).

### Backend (must be deployed — not applied automatically)
- `supabase/migrations/20261005000000_foundation_security.sql`: own-row profile RLS; protected server-owned columns trigger; case-insensitive unique username index + format CHECK (`NOT VALID`, applies to new writes); `check_username_available` RPC; `is_guest()`; chat RLS recursion fix via `is_chat_participant()`; guest write blocking on chat.
- `supabase/functions/update-profile/index.ts`: field whitelist (adds `name`, `onboarding_completed`, `archetypes`), username validation, `409 username_taken`, guest rejection, sanitized errors.
- Deploy: `supabase db push` then `supabase functions deploy update-profile`.

### Client
- `auth_provider.dart`: `AccessLevel` (unauthenticated/guest/member), `continueWithGoogle(GoogleIntent)` with `GoogleAuthOutcome`; `signOut` clears cached profile.
- `auth_repository.dart`: `hasCompletedProfile`; sign-out clears Google account.
- `app_router.dart`: single deterministic redirect (access level + profile load + onboarding), guest-restricted prefixes → login with return target, open-redirect-safe `redirect` param.
- `splash_screen.dart`: no `Future.delayed`/navigation; loading + retry/sign-out on profile failure.
- `login_screen.dart` / `signup_screen.dart`: Google intent handling (no silent account creation / duplicate).
- `onboarding_screen.dart`: username step, debounced backend availability, race handling, save errors surfaced.
- `user_repository.dart` / `user_provider.dart`: removed bad `full_name` write and silent upsert fallback; typed errors; optimistic update with rollback; server authoritative, cache only as offline fallback; guests have transient, non-persisted profile. Temporary: locally earned XP preserved (no server XP yet).
- `local_storage_service.dart`: `clearProfile()`.
- `home_screen.dart`: removed fabricated "nearby people / Tech Startup Mixer" card and hardcoded `/events/1`; reset label uses real clock.
- `communities_repository.dart`: stopped seeding mock communities into the DB.
- New: `profile/domain/username_rules.dart`; `test/auth_access_test.dart`.

## 2026-10-05 — .env Secret Exposure & Media Upload Pipeline Remediation

**Why:** `.env` was packaged as a client asset in `pubspec.yaml` with `SUPABASE_SERVICE_ROLE_KEY`, `MUX_TOKEN_SECRET`, `CLOUDINARY_API_SECRET`, and `IMAGEKIT_PRIVATE_KEY` bundled in plain text. Client code also directly performed API calls with these secrets.

### Backend
- `supabase/.env.local`: Quarantined privileged server secrets (`SUPABASE_SERVICE_ROLE_KEY`, `MUX_TOKEN_ID`, `MUX_TOKEN_SECRET`, `CLOUDINARY_API_SECRET`, `IMAGEKIT_PRIVATE_KEY`) for local Edge Function execution.
- `supabase/functions/sign-media-upload/index.ts`: Created new authenticated Edge Function delegating Mux direct upload provisioning, Mux asset status polling, and server-side HMAC signing for Cloudinary and ImageKit.

### Client
- `.env`: Stripped of all server secrets and service role keys. Retains only client-safe public config (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, `CLOUDINARY_CLOUD_NAME`).
- `.env.example`: Added reference file documenting strict separation between client-safe config and server-side secrets.
- `lib/core/env/env.dart`: Hardened with compile-time `--dart-define` support, clean getters, and automatic memory sanitization (`Env.sanitizeEnvironment()`) that detects and purges prohibited secret keys if ever accidentally loaded.
- `lib/core/media/providers/mux_service.dart`: Removed all raw `MUX_TOKEN_ID`/`MUX_TOKEN_SECRET` client references; direct uploads and polling now delegate via `sign-media-upload`.
- `lib/core/media/providers/cloudinary_service.dart`: Removed client-side HMAC computation and `CLOUDINARY_API_SECRET`; requests server-signed parameters from `sign-media-upload`.
- `lib/core/media/providers/imagekit_service.dart`: Removed client-side HMAC computation and `IMAGEKIT_PRIVATE_KEY`; requests server-signed parameters from `sign-media-upload`.
- `lib/features/identity/auth/data/auth_repository.dart` & `oauth_server_service.dart`: Converted from raw `dotenv.env` lookups to typed `Env` getters.
- `lib/features/identity/profile/presentation/settings_screen.dart`: Fixed deprecated `activeColor` warnings (migrated to `activeTrackColor`).
- `lib/features/interaction/connect/presentation/connect_screen.dart`: Removed unnecessary Cupertino import.
- `test/env_security_test.dart`: Added unit tests verifying clean environment loading and memory purging of server secrets.
- Verification: `flutter analyze` 0 warnings / 0 errors; `flutter test` 10/10 passed.

## 2026-10-05 — Home Dashboard & Feed Stabilization (Audit Phase 2)

**Why:** The video feed relied on 5 hardcoded mock videos and swallowed errors with silent `catch (_) {}`. Bottom navigation had gesture traps (`onTap: () {}` absorbing clicks on the feed tab). Feed models didn't map live DB column names (`user_id` vs `creator_id`), guests could like/share without guards, and Home lacked any pathway into the Feed.

### Client Changes
- `lib/core/shell/main_shell.dart`: Removed `GestureDetector(onTap: () {})` overlay traps that blocked navigation to the Feed.
- `lib/shared/models/creator_video.dart`: Fixed schema mismatch in `CreatorVideo.fromJson`:
  - Added fallback mapping for `user_id` as creator ID (live `videos` schema).
  - Parsed joined Supabase `profiles` relation for creator name (`name` or `username`) and `avatar_url`.
- `lib/features/interaction/feed/data/feed_repository.dart`:
  - Completely purged all 5 hardcoded static mock videos (`_sampleVideos`).
  - Implemented direct fallback to live Supabase `videos` table (`video_type = 'feed'`) when edge function is unavailable or caching offline.
  - Added Hive offline feed cache preservation.
  - Surfaced real typed errors instead of silent empty lists.
- `lib/features/interaction/feed/presentation/feed_screen.dart`:
  - Added tactile haptic feedback on like, comment, share, bookmark, and mute interactions.
  - Implemented guest-protection modal intercepting like, comment, and bookmark actions with direct signup/login prompts.
  - Built high-aesthetic branded empty state when feed contains zero videos, with direct CTA to the `/create` flow.
- `lib/features/interaction/home/presentation/home_screen.dart`:
  - Added dedicated "Watch Experience Feed" glassmorphic spotlight card in the primary home feed.
  - Added "Experience Feed" shortcut to Quick Actions bar.
- Verification: `flutter analyze` 0 warnings / 0 errors; `flutter test` 10/10 passed.

## 2026-10-05 — Create & Upload Experience Flow Stabilization (Audit Phase 3)

**Why:** Camera initialization failures, simulator environments, and denied permissions left users stranded on infinite loading spinners with swallowed `CameraException` logs. In the experience sharing flow, community destinations were hardcoded to `'community_id': '1'` (violating Postgres UUID type constraints), mock lists of people and communities were shown in bottom sheets, and failed uploads still showed fake success notifications. Additionally, `stories_repository.dart` injected 4 fabricated stories (`defaultSeedStories`) whenever the backend was empty.

### Client Changes
- `lib/features/interaction/create/presentation/create_screen.dart`:
  - Added honest camera state tracking (`_cameraErrorMessage`) with informative UI fallback on permission denials, missing hardware, or initialization errors.
  - Provided explicit actionable buttons ("Try Again", "Open Gallery", and "Text Mode") instead of infinite progress spinners.
  - Implemented responsive camera aspect ratio scaling.
  - Added capture error surfacing via `ScaffoldMessenger` for photo and video recording failures.
  - Added text validation preventing users from posting empty text posts.
- `lib/features/interaction/create/presentation/share_experience_screen.dart`:
  - Connected community selection to real `communitiesProvider`, with dynamic search filtering, active selection chips, and clear options.
  - Replaced mock people tagging with real username tagger supporting `@` handle entry and chip management.
  - Replaced hardcoded `'community_id': '1'` with the actual selected community UUID (or `null` when posting to story/feed only).
  - Enforced destination validation: requires selecting at least one destination (Feed, Story, or Community) before proceeding.
  - Hardened upload error handling: halts execution and alerts user if media upload fails rather than proceeding to publish with null URLs.
  - Surfaces real backend rejection messages from `publish-experience` (HTTP 4xx/5xx).
- `lib/features/interaction/home/data/stories_repository.dart`:
  - Completely purged `defaultSeedStories` (Sarah C., Marcus T., Elena V., David K.) from both production (`SupabaseStoriesRepository`) and mock repositories.
  - Stories feed now honestly displays real user-created stories, and shows "Your Story" with a create badge when empty.
