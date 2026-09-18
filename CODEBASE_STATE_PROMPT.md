# QUEST PLATFORM: COMPREHENSIVE SYSTEM AUDIT & AGENT ONBOARDING BRIEF
> **Document Purpose**: Single self-contained prompt to onboard an incoming AI agent or software engineer into the Quest development team. Covers active architecture, domain models, database migrations, edge functions, dependencies, screen implementations, and current progress.
> **Date**: September 18, 2026
> **Repository**: `Quest` (Flutter Multiplatform + Supabase Backend)
> **Analysis Health**: `flutter analyze` -> **0 Warnings, 0 Errors (100% Clean)**

---

## 1. Executive Summary & Architectural Vision

Quest is a **Social Operating System** designed for real-world connection, community building, and personal growth. It merges high-agency gamification (XP, Archetypes, Streaks, Daily Quests) with high-density communication tools (Telegram-style messaging, WhatsApp-style status updates, TikTok-style short-form video feed, Live Audio stages, and PostGIS-driven proximity radar).

### Core Architectural Paradigm
- **Client Architecture**: Flutter 3.12+ (Dart 3.x) with Riverpod 3.x (`AsyncNotifier`, `StreamNotifier`, `Notifier`), declarative routing via `GoRouter 17.x` with `ShellRoute` navigation and auth guards.
- **Backend Architecture**: Supabase (PostgreSQL 15+, Supabase Auth, GoTrue OAuth 2.1 Server, Realtime WebSockets, Storage Buckets, and 37 Deno TypeScript Edge Functions).
- **Domain-Driven Directory Organization**: Code is strictly segmented across 6 core platform layers:
  1. `lib/features/identity/` (Auth, Profile, XP, Leaderboards)
  2. `lib/features/interaction/` (Home/Stories, Video Feed, Messaging/Chat, Connect/User Discovery, Explore/Global Search, Create/Media Ingestion, Audio Stage)
  3. `lib/features/society/` (Communities/Guilds, Events, Organization Portal)
  4. `lib/features/world/` (Radar Proximity HUD, Places, Geo Nodes)
  5. `lib/features/economy/` (Commerce, Opportunities/Jobs, Wallet & Coins)
  6. `lib/features/intelligence/` (AI Personal Coach, Moderation & Recommendations)

---

## 2. Key Package Dependencies & Roles (`pubspec.yaml`)

| Category | Package | Version | Architectural Role in Quest |
|---|---|---|---|
| **State & Navigation** | `flutter_riverpod` | `^3.4.2` | Core reactive state management (`AsyncNotifier`, `StreamNotifier`, `family` providers) |
| | `go_router` | `^17.3.0` | Declarative routing, `ShellRoute` (persistent bottom/side nav), and auth state redirect guards |
| **Backend & Auth** | `supabase_flutter` | `^2.16.0` | Postgres queries, real-time WebSocket streams, Auth session, Storage API |
| | `google_sign_in` | `^6.2.2` | Native in-app Google authentication returning ID tokens for Supabase Auth |
| | `flutter_dotenv` | `^5.1.0` | Local `.env` secrets ingestion (`SUPABASE_URL`, `MUX_TOKEN`, `CLOUDINARY_SECRET`, etc.) |
| **Media & Video** | `video_player` | `^2.8.6` | Native mobile and web video playback engine |
| | `chewie` | `^1.8.1` | High-level media player wrapper and controls |
| | `story_view` | `^0.16.6` | Instagram/WhatsApp story progression carousel engine |
| | `visibility_detector` | `^0.4.0+2` | Viewport visibility hooks for auto-play/pause in the TikTok-style vertical video feed |
| | `v_video_compressor` | `^2.2.1` | On-device video compression before network upload |
| | `flutter_image_compress` | `^2.5.1` | Native bitmap image compression for fast avatar and feed uploads |
| | `image_picker` | `^1.2.3` | Multi-image and video picking from camera and system gallery |
| | `image_cropper` | `^12.2.1` | Aspect ratio cropping for profile avatars and community banners |
| | `camera` | `^0.12.0+2` | Real-time hardware camera stream for in-app media recording |
| | `cached_network_image`| `^3.4.1` | Disk and memory caching with placeholder fallbacks |
| **Chat & Social** | `v_chat_bubbles` | `^2.2.0` | Authentic 1:1 Telegram message bubbles, continuous corner radii, grouping, date chips |
| | `voice_note_kit` | `^1.3.3` | Voice recording, audio waveform scrubbers, and synced audio playback |
| | `flutter_link_previewer`| `^4.2.0` | OpenGraph rich link card scraper and preview bubble generator |
| | `emoji_picker_flutter`| `^4.5.4` | Comprehensive emoji keyboard picker sheet |
| | `hive` / `hive_flutter` | `^2.2.3` / `^1.1.0`| High-speed offline key-value storage for message threads, drafts, and outbox queue |
| **UI, Design & Polish** | `google_fonts` | `^8.2.0` | Inter and Outfit typography runtime loading |
| | `shimmer` | `^3.0.0` | Skeleton loading animations for glassmorphic cards |
| | `flutter_svg` | `^2.3.0` | High-fidelity vector glyph and logo rendering |
| | `timeago` | `^3.7.1` | Human-readable relative time formatting (`5m ago`, `2d ago`) |
| | `secure_application` | `^4.1.0` | Privacy shield preventing screenshots and app switcher previews |
| **System & Network** | `dio` | `^5.11.0` | Resilient HTTP client for direct chunked Mux streaming and Cloudinary signatures |
| | `connectivity_plus` | `^7.3.1` | Network connectivity listener for offline outbox sync |
| | `flutter_local_notifications` | `^18.0.1` | Android Notification Channels (`quest_uploads`, `quest_chat`, `quest_general`) |
| | `crypto` | `^3.0.7` | SHA-1 / SHA-256 signature hashing for direct cloud uploads |

---

## 3. Database Schema & Migration History (`supabase/migrations/`)

1. **`20260805051634_init_schema.sql`**: Initial database foundation. Created tables: `communities` (guilds, member counts, colors, tags), `events` (time, date, location, RSVP, XP reward), `stories` (ephemeral updates), and `leaderboard` (rank, score, badges). Enforced baseline Row Level Security (RLS).
2. **`20260805060000_phase4_schema.sql`**: Extended platform tables. Created `profiles` (name, avatar, level, xp, streak, archetype), `daily_quests` (checklist gamification), `chat_messages`, and `radar_nodes` (geospatial blips).
3. **`20260805060500_leaderboard_fix.sql`**: Fixed leaderboard unique constraints and added performance indices for score sorting.
4. **`20260821000000_quest_feed_integration.sql`**: Full video subsystem integration. Created `creator_videos`, video comments, atomic like counts, views tracking, tag filtering, email job queues, and notification dispatch pipelines.
5. **`20260826000000_add_media_to_stories.sql`**: Added `media_url` and `media_type` columns to `stories` table.
6. **`20260827192200_add_mux_asset_id_to_stories.sql`**: Integrated Mux streaming columns (`mux_asset_id`, `mux_playback_id`) into `stories`.
7. **`20260827192800_schedule_story_cleanup_cron.sql`**: Added automated 24-hour cleanup cron job for ephemeral stories.
8. **`20260828000000_profile_and_chat_schema.sql`**: Modernized 1:1 chat architecture:
   - Extended `profiles` with `username`, `avatarUrl`, and `bio`.
   - Created `chat_rooms` (multi-user and 1:1 metadata, last message text, last message time).
   - Created `chat_participants` join table with RLS ensuring users can only read threads they participate in.
   - Enhanced `chat_messages` with `roomId`, `senderId`, and `status` (`sending`, `sent`, `delivered`, `read`).
9. **`20260918000554_unify_videos_and_phase3_schema.sql`**: Major modernization migration:
   - Created `user_trust_scores` (scores, Bronze/Silver/Gold/Platinum tier levels).
   - Created unified `videos` table supporting multiple content archetypes: `story`, `feed`, `chat`, `community`, `event`, `vlog`.
   - Added trust scores, engagement scores, and metadata arrays (`tags`, `community_id`, `event_id`).
   - Cleaned up 12 legacy VEE tables and unified `creator_videos` into `feed_videos`.
   - Automated hourly `pg_cron` worker `cleanup_old_stories_24h`.
10. **`20260918000629_phase3_mock_seed_data.sql`**: Deterministic mock seeds for profiles, trust scores, video feeds, quests, and events.

---

## 4. Supabase Edge Functions Catalog (`supabase/functions/`)

The repository includes **37 Deno TypeScript Edge Functions** covering security, ingestion, notifications, and analytics:

| Edge Function | Description & Responsibility |
|---|---|
| `publish-experience` | Centralized publishing pipeline across Feed, Stories, and Communities with schema normalization |
| `interact-video` | Atomic handling of video likes and comments, updating engagement scores |
| `send-message` | Chat transmission gateway updating thread metadata (`lastMessageText`, `lastMessageTime`) and pushing FCM alerts |
| `update-profile` | Sanitized user profile updates preventing manipulation of protected attributes (`trust_score`, `xp`) |
| `delete-experience` | Cascading deletion of videos and stories across storage and database with creator verification |
| `create-mux-upload` | Generates authenticated direct Mux video upload URLs via Mux Video API |
| `mux-webhook` | Listens for Mux asset readiness, encoding completion, and error events |
| `sync-mux-status` | Periodic synchronizer validating status of pending video assets |
| `get-feed` | Algorithmic feed fetcher sorting by trust score, engagement, and recency |
| `like-video` | Atomic like toggling with user relation management |
| `batch-interactions` | Batch recorder for views, impressions, and watch duration to prevent write hotspots |
| `aggregate-engagement` | Calculates rolling creator engagement metrics and trust score adjustments |
| `fetch-daily-trending` | Daily cron calculating trending items across Quests, Events, and Guilds |
| `recalculate-community-trending` | Recalculates community guild trending rankings based on active interactions |
| `recalculate-post-trending` | Recalculates hot/trending rankings for community posts |
| `notify-trending` | Dispatches push notifications for breaking viral content |
| `notify-airing-today` | Automated daily reminder for events scheduled within 24 hours |
| `process-notification-jobs` | Background worker pulling pending notification jobs and routing to FCM |
| `process-email-queue` | Transactional email processor dispatching through Resend API |
| `queue-email` | Enqueues outbound system and verification emails |
| `story-cleanup` | Garbage collector purging stories older than 24 hours |
| `fix-stuck-video` | Recovery utility resetting videos stuck in processing status |
| `backfill-mux` | Database migration helper backfilling playback IDs |
| `creator-application-review` | Handles creator tier review and verification workflows |
| `delete-creator-video` | Administrative deletion of creator video posts |
| `update-creator-video` | Metadata editor for creator videos (titles, tags, thumbnail) |
| `admin-moderate-video` | Content moderation endpoint approving or rejecting flagged media |
| `admin-view-reports` | Admin dashboard feed listing reported users and posts |
| `submit-report` | Client reporting endpoint for harassment, spam, and inappropriate content |
| `moderate-message` | Automated text safety screening for chat messages |
| `block-user` | Bidirectional user blocking and thread silencing |
| `delete-account` | Comprehensive GDPR/Account deletion cascade |
| `store-deletion-request` | Legal audit log for data deletion compliance |
| `broadcast-announcement` | Guild leader announcement broadcast to all community members |
| `create-community-post` | Creates discussion threads and announcements in community guilds |
| `fetch-youtube-trailers` | Imports external video trailer metadata |
| `join-waitlist` | Captures early-access waitlist submissions |

---

## 5. Screen Inventory & Route Catalog (GoRouter 17.x)

Every screen is mapped to a domain and route in `lib/core/router/app_router.dart`:

| Route | Screen Class | File Path | Shell | Key Purpose |
|---|---|---|---|---|
| `/` | `SplashScreen` | `lib/features/identity/auth/presentation/splash_screen.dart` | No | App boot animation, Supabase session check, and router routing |
| `/landing` | `LandingScreen` | `lib/features/identity/auth/presentation/landing_screen.dart` | No | Hero onboarding landing page with primary value proposition |
| `/login` | `LoginScreen` | `lib/features/identity/auth/presentation/login_screen.dart` | No | Sign In / Sign Up toggle, Supabase Auth, Native Google Sign-In, password reset |
| `/oauth/consent` | `OAuthConsentScreen` | `lib/features/identity/auth/presentation/oauth_consent_screen.dart` | No | OAuth 2.1 / OIDC consent screen for MCP servers and 3rd party apps |
| `/onboarding` | `OnboardingScreen` | `lib/features/identity/auth/presentation/onboarding_screen.dart` | No | Archetype selection (`Adventurer`, `Leader`, `Creator`, etc.) |
| `/home` | `HomeScreen` | `lib/features/interaction/home/presentation/home_screen.dart` | **Yes** | Command Center: XP bar, Streak, Daily Quests, `StoriesBar` |
| `/feed` | `FeedScreen` | `lib/features/interaction/feed/presentation/feed_screen.dart` | **Yes** | TikTok-style vertical video feed (`FeedVideoPool`, `TikTokScrollPhysics`) |
| `/explore` | `ExploreScreen` | `lib/features/interaction/explore/presentation/explore_screen.dart` | **Yes** | Discover feed with hero carousels, category cards, search trigger |
| `/explore/search`| `UserSearchScreen` | `lib/features/interaction/explore/presentation/user_search_screen.dart` | No | Glassmorphic Finishd Global Search (ALL, USERS, QUESTS, EVENTS, GUILDS) |
| `/create` | `CreateScreen` | `lib/features/interaction/create/presentation/create_screen.dart` | **Yes** | Camera recording, gallery picker, live preview |
| `/share-experience` | `ShareExperienceScreen`| `lib/features/interaction/create/presentation/share_experience_screen.dart` | No | Publish modal for Feed, Story, or Guild with Mux/Cloudinary gateway |
| `/connect` | `ConnectScreen` | `lib/features/interaction/connect/presentation/connect_screen.dart` | **Yes** | Social hub: embedded `MessagesScreen` tabs + peer discovery CTA |
| `/connect/user_discovery` | `UserDiscoveryScreen` | `lib/features/interaction/connect/presentation/user_discovery_screen.dart` | No | Swipeable peer discovery deck with archetype matching & trust scores |
| `/connect/:id` | `ChatScreen` | `lib/features/interaction/messaging/presentation/chat_screen.dart` | No | 1:1 Telegram replica chat (`v_chat_bubbles`, voice waveforms, wallpaper) |
| `/profile` | `ProfileScreen` | `lib/features/identity/profile/presentation/profile_screen.dart` | **Yes** | User profile, XP level card, Archetype badges, Quests checklist |
| `/profile/:id` | `MemberProfileScreen` | `lib/features/identity/profile/presentation/member_profile_screen.dart` | No | Public peer profile view with trust score badges and connect actions |
| `/edit-profile`| `EditProfileScreen` | `lib/features/identity/profile/presentation/edit_profile_screen.dart` | No | Supabase profile updater (avatar upload, display name, username, bio) |
| `/settings` | `SettingsScreen` | `lib/features/identity/profile/presentation/settings_screen.dart` | No | Multi-feature settings: theme palette, accent colors, cache clearer |
| `/communities` | `CommunitiesScreen` | `lib/features/society/communities/presentation/communities_screen.dart` | No | Guild explorer with category filters and active hubs |
| `/communities/:id` | `CommunityDetailScreen` | `lib/features/society/communities/presentation/community_detail_screen.dart` | No | Guild detail: discussion feed (`CommunityPostCard`), announcements |
| `/events` | `EventsScreen` | `lib/features/society/events/presentation/events_screen.dart` | No | Event calendar and discovery list with category chips |
| `/events/:id` | `EventDetailScreen` | `lib/features/society/events/presentation/event_detail_screen.dart` | No | Event hero banner, countdown, RSVP (+30 XP reward), ticket pass |
| `/organization`| `OrganizationDashboardScreen`| `lib/features/society/organization/presentation/organization_dashboard_screen.dart` | No | Admin metrics, `CreateEventSheet`, `PostAnnouncementSheet` |
| `/radar` | `RadarScreen` | `lib/features/world/radar/presentation/radar_screen.dart` | No | Sci-fi HUD radar with sweep animations, nearby physical hubs, blips |
| `/stage/:id` | `StageScreen` | `lib/features/interaction/stage/presentation/stage_screen.dart` | No | Live audio room with sinusoidal soundwave equalizer & emoji reactions |
| `/leaderboard` | `LeaderboardScreen` | `lib/features/identity/leaderboard/presentation/leaderboard_screen.dart` | No | Global & archetype leaderboards with top-3 podium and season timer |
| `/create-story`| `StoryCreatorScreen` | `lib/features/interaction/home/presentation/story_creator/story_creator_screen.dart` | No | Story publishing canvas with gradient backgrounds and text overlays |

---

## 6. Core Subsystems & Technical Details

### 6.1. Telegram Replica Messaging Engine
- **Bubbles & Grouping**: Utilizes `v_chat_bubbles: ^2.2.0` with `VBubbleStyle.telegram` and `VBubbleTheme.telegramDark()`. Consecutive messages cluster automatically based on sender and timestamps.
- **Doodle Wallpaper**: Custom canvas painter `TelegramWallpaper` renders the iconic Telegram textured canvas with theme-aware opacity.
- **Waveform Voice Notes**: `VoiceNoteBubble` integrates `voice_note_kit` for real-time waveform seeking, duration display, and synchronized playback.
- **Input Composer**: Finishd-style WhatsApp input (`WhatsAppTextField`) with attachments bottom sheet and full emoji keyboard (`AppEmojiPicker`).
- **Offline Persistence**: Local Hive database cache (`LocalDatabaseService`) stores message drafts and offline outbox queues, synchronizing automatically when network connectivity returns.

### 6.2. Media & Video Upload Gateway (`MediaServiceGateway`)
- **Resilient 2-Tier Upload**:
  1. **Primary**: Mux direct video ingestion via `https://api.mux.com/video/v1/uploads`. Uses `Dio` for chunked uploads and fixed 2-phase polling (`/video/v1/uploads/$id` -> `/video/v1/assets/$assetId`) to resolve the HLS playback URL (`https://stream.mux.com/<id>.m3u8`).
  2. **Fallback**: Automatic fallback to Cloudinary when Mux quotas are exhausted (HTTP 402/429 `MuxQuotaException`) or API credentials are null. Signs uploads using client-side SHA-1 hashing (`crypto`).
- **Image Uploads**: Direct byte streaming through ImageKit/Cloudinary, bypassing platform-specific file system limitations on web (`kIsWeb`).
- **Video Feed Caching**: `FeedVideoPool` maintains a pooled cache of active video controllers, pre-loading the next video in the feed and disposing offscreen players.

### 6.3. WhatsApp-Style Ephemeral Status Updates
- **`StoriesBar`**:
  - Renders user's story avatar with gray border when no stories exist (tapping opens `/create`).
  - Activates a vibrant glowing Quest Blue ring when stories are active, showing the latest media thumbnail.
- **`MyStatusModal`**: Shows the user's uploaded updates, timestamps, view counts, and a 3-dots popup menu to view or delete stories.
- **`StoryViewerModalV2`**: Fullscreen viewer that syncs video duration with the native video player (disabling looping) and defaults images/text to 8 seconds, with hold-to-pause gestures.

### 6.4. Finishd-Styled Glassmorphic Global Search
- **Endpoint**: `/explore/search` (`UserSearchScreen`).
- **5 Tabs**: `ALL`, `USERS`, `QUESTS`, `EVENTS`, `GUILDS`.
- **Archetype Pills**: Horizontal filter bar filtering users by archetype (`Adventurer`, `Leader`, `Organizer`, `Creator`, `Connector`, `Strategist`).
- **Trust Scores**: Displays member reputation tiers (e.g., *Platinum 95.5*, *Gold 82.0*).
- **Debounced Repository**: `GlobalSearchRepository` debounces queries and queries Supabase tables with fallback trending seeds.

### 6.5. Authentication & OAuth 2.1 Identity Server
- **Supabase Auth**: Email/password sign-in and sign-up with email verification session checks.
- **Native Google Sign-In**: In-app modal via `google_sign_in` passing ID tokens to Supabase without opening browser redirects.
- **OAuth 2.1 Server**: Built-in consent interface (`/oauth/consent`) allowing Quest to function as an identity provider for external apps and MCP tools via authorization codes and token grants.

---

## 7. Current Project Status & Immediate Next Steps

### Completed & Stable
- ✅ All 28+ screens built, routed, and styled with Quest dark OLED design language (`AppColors`, `AppTheme`).
- ✅ 100% clean `flutter analyze` report (0 errors, 0 warnings).
- ✅ Supabase database migrations unified under modern `videos` and `user_trust_scores` schema.
- ✅ Mux + Cloudinary resilient video upload fallback gateway.
- ✅ Telegram replica chat engine with voice notes, wallpapers, and offline Hive outbox.
- ✅ WhatsApp-style status updates with viewer v2 and view counter tracking.
- ✅ Living architectural documentation synchronized in `docs/architecture/`.

### Priorities for Incoming Agent / Developer
1. **Live Audio WebRTC Integration (`/stage`)**: Replace mock stage participants with real audio broadcasting via Agora.io (`agora_rtc_engine`) or LiveKit.
2. **PostGIS Real-Time Proximity (`/radar`)**: Integrate PostGIS spatial queries into Supabase RPC for live distance calculation between users and physical hubs.
3. **Push Notifications (FCM Integration)**: Connect `app_notification_service.dart` to Firebase Cloud Messaging for incoming messages and event notifications.
4. **Experience Economy Module (`lib/features/economy/`)**: Build out the presentation UI for the Marketplace (`commerce`), Job/Bounty Board (`opportunities`), and Quest Coins balance (`wallet`).

---
*Generated by Antigravity Agent for Quest Engineering Team. Use this document as the system prompt for any developer or subagent working on this repository.*
