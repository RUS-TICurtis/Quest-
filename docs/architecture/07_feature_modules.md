_Last Modified: 2026-10-09_

# 7. Feature Modules

## Feature Inventory

| Feature | Path | Domain | Status | Backend |
|---|---|---|---|---|
| **Auth & OAuth 2.1** | `lib/features/identity/auth/` | Identity | ✅ Complete | Supabase Auth + Google Native + OAuth 2.1 Server |
| **Profile / XP** | `lib/features/identity/profile/` | Identity | ✅ Complete | `profiles`, `daily_quests`, `community_members`, `event_rsvps`, `award_xp` RPC |
| **Leaderboard** | `lib/features/identity/leaderboard/` | Identity | ✅ Complete | `leaderboard` table & season rankings |
| **Home (Mission Control)** | `lib/features/interaction/home/` | Interaction | ✅ Complete | XP Bar, Quests, Gamification Cockpit, Feed Spotlight |
| **Video Feed** | `lib/features/interaction/feed/` | Interaction | ✅ Complete | Live `videos` table fallback, `FeedVideoPool`, Quest Share Sheet, Guest Intercepts |
| **Explore & Global Search** | `lib/features/interaction/explore/` | Interaction | ✅ Complete | Multi-entity repository & Glassmorphic UI (purged all mocks) |
| **Connect Hub (4 Pillars)** | `lib/features/interaction/connect/` | Interaction | ✅ Complete | Messages, Communities, Events, Radar unified tabs with deep linking |
| **Create & Share Experience** | `lib/features/interaction/create/` | Interaction | ✅ Complete | Front/rear camera switch, torch, vlog timer, typed payload, quest linking, Mux/Cloudinary gateway |
| **Notifications** | `lib/features/interaction/notifications/` | Interaction | ✅ Complete | `notifications` table, in-app alerts, interactive feed |
| **Messaging / Chat** | `lib/features/interaction/messaging/` | Interaction | ✅ Complete | Supabase Realtime + Hive local outbox + purged all demo threads + baseline empty state |
| **Stage (Audio)** | `lib/features/interaction/stage/` | Interaction | 🟡 Mock Data | Sinusoidal physics canvas, Agora/LiveKit pending |
| **Communities / Guilds** | `lib/features/society/communities/` | Society | ✅ Complete | `communities`, `community_members` (backend join/leave & XP wired) |
| **Events** | `lib/features/society/events/` | Society | ✅ Complete | `events`, `event_rsvps` (backend RSVP & XP wired) |
| **Organization Portal** | `lib/features/society/organization/` | Society | 🟡 Scaffold | Host & guild management dashboards |
| **Radar (Proximity)** | `lib/features/world/radar/` | World | ✅ Complete | Live `profiles` HUD canvas & truthful empty state |
| **Commerce & Wallet** | `lib/features/economy/` | Economy | 🟡 Prototype | Models & state providers scaffolded |

## Module Structure (per feature)

Each feature follows this layout:
```
lib/features/<feature>/
  data/
    <feature>_provider.dart   # AsyncNotifier + state model(s)
    <feature>_repository.dart # Abstract + Supabase implementation
  presentation/
    <feature>_screen.dart     # Primary screen
    widgets/                  # Local widget components
```

## Key Notifier Catalog

| Provider | Type | Key Actions |
|---|---|---|
| `authProvider` | `Notifier<AuthState>` | `signInWithEmail()`, `signOut()`, `signUpWithEmail()`, `signInWithGoogleNative()` |
| `userProvider` | `AsyncNotifier<UserState>` | `addXp()`, `toggleQuest()`, `updateName()`, `toggleRsvp()` |
| `eventsProvider` | `AsyncNotifier<EventsState>` | `toggleRsvp()`, `addEvent()`, `setFilter()` |
| `communitiesProvider` | `AsyncNotifier<CommunitiesState>` | `toggleJoin()`, `addCommunity()`, `setCategory()`, `setSearchQuery()` |
| `chatProvider` | `StreamNotifier<ChatState> (Supabase Realtime)` | `sendMessage()`, `sendVoiceNote()`, `markThreadRead()`, `toggleReaction()`, `votePoll()`, `pinMessage()`, `deleteMessage()` |
| `stageProvider(id)` | `AsyncNotifier<StageState>` (family) | `toggleMic()`, `toggleHandRaise()`, `sendReaction()` |
| `radarProvider` | `AsyncNotifier<RadarState>` | `selectHub()`, `checkInToHub()` |
| `leaderboardProvider` | `AsyncNotifier<LeaderboardState>` | `setTab()`, `setArchetype()` |
| `storiesProvider` | `AsyncNotifier<List<StoryItem>>` | `addStory()`, `deleteStory()`, `markAsSeen()` |
| `globalSearchProvider` | `StateNotifier<GlobalSearchState>` | `onQueryChanged()`, `setArchetypeFilter()`, `clearSearch()`, `loadTrending()` |

## Telegram Replica Messaging Engine

The messaging architecture is built as a **1:1 Telegram replica** powered by `v_chat_bubbles: ^2.2.0`:
- **Visual Style & Themes**: `VBubbleStyle.telegram` and `VBubbleTheme.telegramDark()` rendering authentic Telegram gradients, tail shapes, date chips (`VDateChip`), and read checkmarks.
- **Dynamic Bubble Grouping**: Resolves message sender and temporal proximity via `VMessageGrouping.resolve(...)`, seamlessly clustering consecutive bubbles with custom continuous corner radii.
- **Canvas & Wallpapers**: `TelegramWallpaper` paints Telegram's iconic subtle textured doodle canvas with theme-aware opacity.
- **Rich Message Types**: Supports `VTextBubble` (full markdown parsing, mentions, links), `VImageBubble`, `VVoiceBubble` (waveform scrubber), `VFileBubble`, and interactive `VPollBubble`.
- **Interactive Capabilities**:
  - Swipe-to-reply with active quotation preview banner (`VReplyData`).
  - Actor-aware emoji reaction pills (`VBubbleReaction`) with quick toggle.
  - In-chat search with real-time character-level substring highlighting (`searchQuery`).
  - Category tabs on `MessagesScreen` (*All, Direct, Groups, Channels, Bots*), unread count pills, and floating action pencil button.
- **Input System**: Features a port of Finishd's WhatsApp-style input field (`WhatsAppTextField`) with integrated attachment sheets rendered below the input box and a fully themed, persistent emoji picker (`AppEmojiPicker`).

## Media, Camera & Social OS Publishing Engine

The media capture, ingestion, and story distribution layer connects kinetic real-world participation with social sharing:
- **Full-Bleed Camera Viewfinder (`CreateScreen`)**:
  - Automatically suppresses `MainShell`'s bottom navigation bar on the Create tab (`/create`) for an edge-to-edge camera experience without navigation button collisions.
  - **Hardware Controls**: Front/rear lens switching (`_switchCamera()`), flash/torch cycling (`FlashMode.off -> auto -> torch`), and top floating glass dismiss button (`Icons.close`).
  - **Vlog Capture Mechanics**: Integrated active recording timer (`● REC 00:15 / 01:00`), 60-second automatic duration cutoff, and SVG radial circular progress stroke around the shutter button.
  - **Text Experience Canvas**: Multi-theme gradient palette selector (Quest Blue, Midnight Slate, Aurora Magenta, Emerald, Crimson) with stylized quote typography.
- **Typed Submission Contract (`CreateSubmissionPayload`)**:
  - Discriminated payload model (`image`, `video`, `text`) decoupling text status creation from filesystem file loaders, eliminating crashes.
- **Interactive Review & Experience Publishing (`ShareExperienceScreen`)**:
  - Responsive 9:16 interactive video review container with central play/pause gesture and audio mute/unmute toggle.
  - Retake / discard action returning cleanly to camera mode.
  - **Quest Proof Linking**: Creators can link active daily quests (`QuestItem`) to verify real-world participation and receive dynamic XP rewards upon publication (`+25 XP`).
  - Segmented destination pills (*Story 24h*, *Main Feed*, *Target Guild*).
- **Downstream Sharing & Story Reactions**:
  - **Quest Share Sheet (`FeedScreen`)**: Tapping share triggers a custom bottom sheet with *Copy Link* (`https://qwst.run/experience/:id`), *Send in Chat*, and *Guild Post*.
  - **Interactive Story Viewer (`StoryViewerModalV2`)**: Includes quick emoji reaction pills (`🔥`, `❤️`, `👏`, `🎯`), direct reply input, and view count pills for owned stories.
- **Web (`kIsWeb`) Compatibility**: Uses byte streams (`XFile.readAsBytes()`) to bypass `dart:io` restrictions on web.
- **Multi-Cloud Gateways**: Mux direct video ingestion via signed URLs with Cloudinary automatic fallback.

## Authentication & Account Lifecycle

The authentication stack is powered by Supabase Auth (`lib/features/identity/auth/`):
- **Sign In & Sign Up Flow (`LoginScreen`)**:
  - Segmented toggle between **Sign In** and **Create Account**.
  - Direct integration with Supabase Auth (`signInWithPassword` and `signUp`).
  - Full validation: email format checks, min 6-char passwords, password confirmation checks for registrations.
  - "Forgot Password?" dialog triggering Supabase `resetPasswordForEmail`.
  - Social login: **Native In-App Google Sign-In** (`google_sign_in: ^6.3.0` + Supabase `signInWithIdToken`), opening an in-app bottom sheet/modal card without leaving or redirecting the application, with fallback to web OAuth redirect.
  - **Email Confirmation Session Verification**: Detects when email confirmation is required (`session == null`) and prompts the user to verify their inbox before switching to Sign In, preventing redirect loops back to splash/landing.
  - Clean error mapping to user-friendly messages for standard Supabase `AuthException` states.
- **Sign Out & Session Revocation**:
  - `authProvider.notifier.signOut()` revokes the Supabase session, resets authentication state, and redirects the user to `/landing`.
  - Confirmation dialog with tactile haptic feedback prevents accidental logouts.
- **OAuth 2.1 Server & MCP Identity Provider (`OAuthConsentScreen` & `OAuthServerService`)**:
  - Acts as an OAuth 2.1 and OpenID Connect (OIDC) identity provider for external apps, developer tools, and Model Context Protocol (MCP) servers.
  - When third-party apps initiate authorization, users land on `/oauth/consent?authorization_id=<id>`.
  - Unauthenticated users are forwarded to `/login?redirect=...` preserving the authorization challenge for seamless post-login authorization.
  - Fetches client info and requested scopes via `GET /auth/v1/oauth/authorizations/{authorization_id}` with Bearer token authentication.
  - Explains requested scopes clearly (`profile`, `email`, `offline_access`, `openid`, `phone`, or custom scopes).
  - Calls `POST /auth/v1/oauth/authorizations/{authorization_id}/consent` with `{"action": "approve"}` or `{"action": "deny"}`.
  - Seamlessly redirects to the client's registered callback URL with authorization code or error status via `url_launcher`.

## Settings & Profile Management Architecture

The Settings experience (`SettingsScreen` at `/settings`) combines best-in-class features from Telegram, WhatsApp, Snapchat, and Instagram:
- **Profile Header & Quick Actions**:
  - Account summary card with real Supabase avatar, display name, `@username`, and level/XP badge.
  - Dedicated "Edit Profile" button leading directly to `/profile/edit`.
- **Account & Security**:
  - Read-only display of the authenticated Supabase email.
  - In-app "Change Password" dialog leveraging `Supabase.instance.client.auth.updateUser(UserAttributes(password: ...))`.
  - Privacy controls: Story visibility dropdown (*Everyone*, *Friends*, *Private*), read receipts switch (using native `SwitchListTile.adaptive`).
- **Appearance & Accent Customization**:
  - Theme palette selector (*Midnight OLED*, *Deep Cyber Dark*, *Aurora Nebula*, *Emerald Matrix*).
  - Dynamic accent color chips (*Quest Blue*, *Emerald*, *Aurora Purple*, *Crimson*, *Gold*).
  - Tactile haptic feedback toggle (using native `SwitchListTile.adaptive`).
- **Notifications & Storage Controls**:
  - Granular notification toggles (using native `SwitchListTile.adaptive`) for DMs, Group chats, Event alerts, and In-app sounds.
  - Telegram-style storage manager: Wi-Fi only auto-download toggle and instant "Clear Media Cache" button (`imageCache.clear()` and `imageCache.clearLiveImages()`).
- **Organization Portal Link**:
  - Direct route entry to `/organization` for host and community admins.
- **Real Backend Profile Persistence (`EditProfileScreen`)**:
  - Avatar image picker uploading bytes directly through `MediaServiceGateway.uploadImageBytes` (web & mobile compatible).
  - Sleek, glassmorphic fields with updated typography and layout padding.
  - Live editing of `name`, `@username`, and `bio` (with remaining character counter).
  - Syncs directly to Supabase `profiles` table: `{ name, username, bio, avatarUrl, avatar_url }`.
  - Replaces all mock placeholder data with active Supabase user profile info.


## Gamification System

XP and leveling logic lives entirely in `UserNotifier`:
- Each level requires `baseXp * level^1.4` XP (exponential curve)
- Daily quests can be toggled on/off (XP is reverted on un-toggle)
- Streak is tracked as consecutive days with at least one quest completed
- Level-up triggers a dialog via `LevelUpDialog` widget (`lib/features/home/presentation/widgets/level_up_dialog.dart`)

## Global Search & Discovery System (Phase 3 Finishd Port)

The Global Search architecture (`GlobalSearchScreen` / `UserSearchScreen` at `/explore/search`) delivers unified multi-entity discovery powered by Finishd's design language:
- **Glassmorphic App Bar**: `BackdropFilter` (sigma 20) with blurred translucent background, search input, clear button, and close action.
- **5-Tab Filter System**:
  - `ALL`: Categorized feed showing top matches across Users, Quests, Events, and Guilds with "See All" drilldowns.
  - `USERS`: User cards with profile avatar, `@username`, archetype chips, trust score badges (e.g. Platinum 95.5), and quick Chat/Profile actions.
  - `QUESTS`: Gamified challenge cards with XP reward badges and status indicators.
  - `EVENTS`: Rich visual cards with cover imagery, date/time chips, category badges, location, and attendee counters.
  - `GUILDS`: Community cards with category badges, member counts, and descriptions.
- **Archetype Filtering**: Horizontal filter chip bar under the Users tab supporting dynamic filtering across `All`, `Adventurer`, `Leader`, `Organizer`, `Creator`, `Connector`, and `Strategist`.
- **Pre-Search Trending**: Populates dynamic "Trending on Quest" items before query execution so the screen is never empty.
- **Unified Videos Schema**: Centralized `videos` table in Supabase supporting multiple archetypes (`feed`, `story`, `chat`, `community`, `event`, `vlog`) with `trust_score` and hourly `pg_cron` 24h story cleanup.

