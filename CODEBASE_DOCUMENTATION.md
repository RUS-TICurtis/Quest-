# Quest Codebase Architecture & Technical Documentation
> **Living Technical Specification & Architectural Reference**  
> *Version: 1.0.0 | Status: Production Prototype | Ecosystem: Flutter Multiplatform (Android, iOS, Web, Windows, macOS, Linux)*

---

## 📌 Living Documentation Rule & Maintenance Protocol

> [!IMPORTANT]
> **MANDATORY MAINTENANCE PROTOCOL FOR ALL AGENTS & DEVELOPERS:**
> Whenever any file, data model, Riverpod provider, route, screen, theme token, or architectural pattern is created, modified, refactored, or deprecated in this repository:
> 1. **Update this document (`CODEBASE_DOCUMENTATION.md`) synchronously in the exact same turn/commit.**
> 2. Update the corresponding directory tree, file description, model signature, or route mapping.
> 3. Verify that zero lint warnings or architectural discrepancies remain (`flutter analyze`).
> 
> *Never allow documentation to drift from active implementation.*

---

## 1. Executive Summary & Product Vision

### 1.1 The "Social Operating System" Philosophy
Quest is designed not as an attention-harvesting social network with infinite algorithmic feeds, but as a **Social Operating System** optimized for **real-world participation, human connection, collaboration, and personal growth**.

* **Core Tenet**: Optimize for *participation* rather than *attention*.
* **Design Pillars**:
  - **Apple-grade Elegance**: Pixel-perfect spacing, fluid spring curves, cohesive typographic scale.
  - **Linear-grade Clarity**: High density of actionable information without visual noise.
  - **Discord-grade Community Power**: Robust channels, live audio stages, proximity hubs, and roles.
  - **Notion-grade Usability**: Structured, intuitive navigation across organization and personal workspaces.

---

## 2. Technology Stack & Dependencies

| Layer | Technology | Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter SDK | `^3.12.0` | Cross-platform UI toolkit targeting all 6 major platforms |
| **Language** | Dart | `>=3.0.0` | Strongly-typed client logic |
| **State Management** | `flutter_riverpod` | `^3.4.2` | Compile-safe, reactive state notifiers & dependency injection |
| **Routing** | `go_router` | `^17.3.0` | Declarative, URL-aware routing with shell navigation & deep links |
| **Local Database** | `isar` & `isar_flutter_libs` | `^3.1.0+1` | High-performance embedded NoSQL database for offline sync |
| **Cloud Backend** | `supabase_flutter` | `^2.16.0` | Auth, Postgres DB, real-time channels, edge functions, storage |
| **Typography** | `google_fonts` (Inter) | `^8.2.0` | Consistent, readable modern sans-serif typography |
| **Vector & Images** | `flutter_svg`, `cached_network_image` | `^2.3.0`, `^3.4.1` | Crisp SVGs and cached CDN media rendering |
| **Visual Effects** | `shimmer`, `intl` | `^3.0.0`, `^0.20.3` | Polished skeleton loading & localized formatting |

---

## 3. Directory & File Inventory (Exhaustive)

```
Quest/
├── .agents/
│   └── AGENTS.md                                   # Project-level agent rules & living doc guidelines
├── android/                                        # Android native project config (AGP 8.x, Gradle 8.x)
├── ios/                                            # iOS native workspace & Podfile
├── web/                                            # Web platform entry point & PWA manifest
├── windows/, macos/, linux/                        # Desktop native runners
├── lib/
│   ├── main.dart                                   # App entry point (ProviderScope root)
│   ├── app.dart                                    # QuestApp root widget & theme configuration
│   ├── core/
│   │   ├── router/
│   │   │   └── app_router.dart                     # GoRouter configuration & route definitions
│   │   ├── shell/
│   │   │   └── main_shell.dart                     # Persistent bottom/side navigation shell
│   │   └── theme/
│   │       ├── app_colors.dart                     # Standardized design system color palette
│   │       ├── app_theme.dart                      # ThemeData configuration (Dark/Light)
│   │       └── quest_icons.dart                    # Custom rounded line icons & symbols
│   ├── shared/
│   │   └── widgets/
│   │       └── quest_button.dart                   # Standardized interactive button component
│   └── features/
│       ├── auth/
│       │   └── presentation/
│       │       ├── splash_screen.dart              # Launch animation & auth check
│       │       ├── landing_screen.dart             # Welcome screen with value proposition
│       │       └── onboarding_screen.dart          # Multi-step archetype & interest selection
│       ├── home/
│       │   ├── data/
│       │   │   └── stories_provider.dart           # Story models, state notifier & active stories
│       │   └── presentation/
│       │       ├── home_screen.dart                # Command Center (XP, Streak, Stories, Quests)
│       │       ├── story_creator/
│       │       │   └── story_creator_screen.dart   # Live text/media story publishing
│       │       └── widgets/
│       │           ├── stories_bar.dart            # Horizontal story avatars with live ring indicators
│       │           ├── story_viewer_modal.dart     # Fullscreen story carousel with drag-to-dismiss
│       │           └── level_up_dialog.dart        # Celebration modal with confetti & haptics
│       ├── communities/
│       │   ├── data/
│       │   │   └── communities_provider.dart       # Guilds, join state, and category filtering
│       │   └── presentation/
│       │       ├── communities_screen.dart         # Explore guilds, categories, and active hubs
│       │       └── community_detail_screen.dart    # Channels, announcements, and member rosters
│       ├── events/
│       │   ├── data/
│       │   │   └── events_provider.dart            # Events, RSVP management, and filter states
│       │   └── presentation/
│       │       ├── events_screen.dart              # Event discovery & filter chips
│       │       └── event_detail_screen.dart        # Hero banner, RSVP (+30 XP), tickets, share modal
│       ├── radar/
│       │   ├── data/
│       │   │   └── radar_provider.dart             # Proximity hubs, member blips, and check-in state
│       │   └── presentation/
│       │       └── radar_screen.dart               # High-tech HUD radar canvas, sweep animation & pings
│       ├── stage/
│       │   ├── data/
│       │   │   └── stage_provider.dart             # Live room, speaker roster, mic toggle & reactions
│       │   └── presentation/
│       │       └── stage_screen.dart               # Audio room with sinusoidal equalizer & physics emojis
│       ├── messaging/
│       │   ├── data/
│       │   │   └── chat_provider.dart              # Conversation threads & message dispatches
│       │   └── presentation/
│       │       ├── messages_screen.dart            # Conversations list & search
│       │       ├── chat_screen.dart                # Real-time chat, read receipts & voice controls
│       │       └── widgets/
│       │           ├── voice_note_bubble.dart      # Tap-to-seek waveform scrubber with synced playback
│       │           └── link_preview_bubble.dart    # Rich OpenGraph-style preview card
│       ├── leaderboard/
│       │   ├── data/
│       │   │   └── leaderboard_provider.dart       # Season standings & archetype rankings
│       │   └── presentation/
│       │       └── leaderboard_screen.dart         # Top-3 podium, rank list & filter tabs
│       ├── organization/
│       │   └── presentation/
│       │       ├── organization_dashboard_screen.dart # Admin metrics, member analytics & quick actions
│       │       └── widgets/
│       │           ├── create_event_sheet.dart     # Modal form for hosting events
│       │           └── post_announcement_sheet.dart# Modal for broadcasting updates
│       └── profile/
│           ├── data/
│           │   └── user_provider.dart              # Current user profile, XP engine & streak tracking
│           └── presentation/
│               ├── profile_screen.dart             # User stats, archetype tags, badges & portal link
│               ├── member_profile_screen.dart      # Public peer profiles with connect action
│               └── settings_screen.dart            # App preferences, notifications, theme toggles
├── CODEBASE_DOCUMENTATION.md                       # Master technical architecture & living manual
├── DESIGN.md                                       # Core product design principles & specifications
└── pubspec.yaml                                    # Manifest & package dependencies
```

---

## 4. Design System & Visual Foundations

### 4.1 Color Tokens (`AppColors`)
Located at: `lib/core/theme/app_colors.dart`

```dart
// Primary & Background Tones
static const Color questBlue     = Color(0xFF2563EB); // Primary brand interaction & active states
static const Color background    = Color(0xFF030712); // Near-black true OLED canvas
static const Color surface       = Color(0xFF111827); // Deep graphite app bars & navigation containers
static const Color card          = Color(0xFF1F2937); // Elevated cards & tile containers
static const Color border        = Color(0xFF374151); // Clean subtle dividers

// Accent & Status Accents
static const Color midnightSlate = Color(0xFF0F172A); // Secondary backdrop
static const Color auroraPurple  = Color(0xFF7C3AED); // Creative badges & special features
static const Color emerald       = Color(0xFF10B981); // Success, check-ins, online status
static const Color amber         = Color(0xFFF59E0B); // Warnings & streak flames
static const Color crimson       = Color(0xFFEF4444); // Live stages & destructive actions
static const Color skyBlue       = Color(0xFF38BDF8); // Informational pills & links
static const Color gold          = Color(0xFFFBBF24); // XP, level-ups, season leaderboard trophies

// Typography
static const Color textPrimary   = Color(0xFFF9FAFB); // High-contrast primary headings & titles
static const Color textSecondary = Color(0xFFD1D5DB); // Body copy
static const Color textMuted     = Color(0xFF9CA3AF); // Subtitles, timestamps & placeholder text
```

### 4.2 Haptic Engine Standards
Every interaction in Quest provides physical tactile feedback mapped according to semantic hierarchy:
* `HapticFeedback.lightImpact()`: Secondary taps, story navigation, filter chip selection, reaction dispatch.
* `HapticFeedback.selectionClick()`: Tab bar changes, bottom navigation switching.
* `HapticFeedback.mediumImpact()`: Modal dismissals, voice scrubber seeking, toggle actions.
* `HapticFeedback.heavyImpact()`: Level-up unlocks, verified physical hub check-ins, event RSVP confirmation.

---

## 5. Navigation & Routing Architecture (`GoRouter`)

Located at: `lib/core/router/app_router.dart`

The application uses `ShellRoute` to maintain persistent bottom navigation and state across primary tabs, while pushing detail and modal screens cleanly onto the root navigator.

### Route Catalog

| Route Path | Screen Component | Shell? | Description |
| :--- | :--- | :---: | :--- |
| `/` | `SplashScreen` | No | Initial splash animation & authentication gateway |
| `/landing` | `LandingScreen` | No | Value proposition & onboarding entry point |
| `/onboarding` | `OnboardingScreen` | No | Archetype selection & interest onboarding flow |
| `/home` | `HomeScreen` | **Yes** | Primary command center dashboard |
| `/communities` | `CommunitiesScreen` | **Yes** | Guilds directory & community search |
| `/community/:id` | `CommunityDetailScreen`| No | Single community channels & member roster |
| `/events` | `EventsScreen` | **Yes** | Upcoming discovery & filtered events |
| `/event/:id` | `EventDetailScreen` | No | Event hero, RSVP ticket, location & organizer |
| `/messages` | `MessagesScreen` | **Yes** | Direct message threads & inbox |
| `/chat/:id` | `ChatScreen` | No | Real-time chat, voice note waveforms & media previews |
| `/profile` | `ProfileScreen` | **Yes** | User level, archetype matrix, badges & admin link |
| `/profile/member/:id`| `MemberProfileScreen` | No | Peer profile drilldown with connect action |
| `/radar` | `RadarScreen` | No | Proximity HUD scanning radar & hub check-ins |
| `/stage/:id` | `StageScreen` | No | Live audio stage with equalizer & reaction physics |
| `/leaderboard` | `LeaderboardScreen` | No | Season ranking podium & archetype competition |
| `/organization` | `OrganizationDashboardScreen` | No | Admin management, metrics & event creator |
| `/create-story` | `StoryCreatorScreen` | No | Live story creation & broadcasting |
| `/settings` | `SettingsScreen` | No | Account settings, notifications & preferences |

---

## 6. State Management Architecture (Riverpod 3.x)

Every feature module contains a dedicated `data/` provider managing immutable state through a `StateNotifier`:

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Presentation Layer                  │
│       (ConsumerWidget / ConsumerStatefulWidget)             │
└──────────────▲──────────────────────────────┬───────────────┘
               │ watch(provider)              │ read(provider.notifier).action()
┌──────────────┴──────────────────────────────▼───────────────┐
│                    Riverpod StateNotifier                    │
│             (State mutation & business logic)               │
└──────────────▲──────────────────────────────┬───────────────┘
               │ reads/persists               │ updates/syncs
┌──────────────┴──────────────────────────────▼───────────────┐
│              Data Source (Isar DB / Supabase)               │
└─────────────────────────────────────────────────────────────┘
```

### Provider Directory

| Provider | File Location | Key State Entities | Primary Methods |
| :--- | :--- | :--- | :--- |
| `userProvider` | `lib/features/profile/data/user_provider.dart` | `UserState` (name, level, XP, streak, badges, RSVPs, joined guilds) | `addXp()`, `toggleRsvpEvent()`, `toggleJoinCommunity()` |
| `storiesProvider`| `lib/features/home/data/stories_provider.dart` | `Story`, `StoryItem` | `addStory()`, `markStoryViewed()`, `toggleLike()` |
| `eventsProvider` | `lib/features/events/data/events_provider.dart` | `Event`, `selectedFilter` | `setFilter()`, `addEvent()` |
| `communitiesProvider`| `lib/features/communities/data/communities_provider.dart` | `Community`, `selectedCategory` | `setCategory()`, `joinCommunity()` |
| `chatProvider` | `lib/features/messaging/data/chat_provider.dart` | `ChatMessage`, `Conversation` | `sendMessage()`, `markAsRead()` |
| `radarProvider`| `lib/features/radar/data/radar_provider.dart` | `RadarState`, `RadarHub`, `RadarMember` | `selectHub()`, `checkInToHub()` |
| `stageProvider`| `lib/features/stage/data/stage_provider.dart` | `StageState`, `StageSpeaker`, `StageReaction` | `toggleMic()`, `sendReaction()`, `raiseHand()` |
| `leaderboardProvider`| `lib/features/leaderboard/data/leaderboard_provider.dart`| `LeaderboardState`, `LeaderboardEntry` | `setTab()`, `setTimeframe()` |

---

## 7. Deep-Dive Feature Modules

### 7.1 Home & Command Center (`lib/features/home`)
* **`HomeScreen`**: Unified command center displaying personalized greeting, level progress ring, daily quests, streak counter, upcoming pinned events, and stories bar.
* **`StoriesBar` & `StoryViewerModal`**: Displays peer live updates. Tapping opens a story modal with animated progress bars, pause-on-hold, tap left/right to skip, and a vertical drag-down swipe gesture to dismiss.
* **`LevelUpDialog`**: Displays celebratory particle animation, rank banner, unlocked privileges, and multi-stage haptic triggers when reaching higher levels.

### 7.2 Proximity Radar (`lib/features/radar`)
* **`RadarScreen`**: High-tech HUD radar interface.
* **`_RadarSweepPainter`**: Custom painter rendering concentric radar rings, crosshairs, radial gradients, glowing sweep beam, and real-time member blips.
* **Physical Check-In**: Users can verify presence at physical hubs to earn XP and broadcast their presence to nearby guild members.

### 7.3 Live Audio Stage (`lib/features/stage`)
* **`StageScreen`**: Interactive audio room featuring moderators, speakers, and audience members.
* **Equalizer Speaker Rings**: Active speakers have animated multi-bar sinusoidal equalizer rings showing real-time voice activity.
* **Reaction Physics**: Floating emoji reactions travel upwards with horizontal sinusoidal drift and rotational tilt before gracefully fading out.

### 7.4 Messaging & Voice Notes (`lib/features/messaging`)
* **`ChatScreen`**: Instant messaging with read receipt double ticks (`Icons.done_all`).
* **`VoiceNoteBubble`**: Visual audio waveform scrubber supporting interactive tap-to-seek, real-time playback timer, and play/pause haptics.
* **`LinkPreviewBubble`**: OpenGraph card preview for shared URLs.

### 7.5 Events & Communities (`lib/features/events`, `lib/features/communities`)
* Filter chips for instant categorization (Today, Tomorrow, Weekend, Virtual).
* Event RSVPs grant immediate +30 XP and store tickets in user inventory.
* Communities support channel lists, announcements, and direct member messaging.

### 7.6 Organization Portal (`lib/features/organization`)
* Administrative dashboard for event hosts, companies, and university clubs.
* Provides real-time attendee statistics, ticket sales, engagement metrics, and announcement dispatch sheets.

---

## 8. Multi-Platform Build & Configuration Notes

### Android (`android/`)
* **Namespace Resolution**: `isar_flutter_libs` is fully configured for modern AGP 8.x+ compatibility.
* `android/app/build.gradle.kts` specifies `compileSdk = 35`, `minSdk = 24`, `targetSdk = 35`.
* Release builds: `flutter build apk --release` runs cleanly.

### iOS (`ios/`)
* Podfile configured with standard iOS deployment target 13.0+.

### Web & Desktop
* Configured with responsive layouts. Side navigation is utilized on desktop widths (>900px), collapsible drawer on tablet widths (600px–900px), and bottom navigation on mobile widths (<600px).

---

## 9. Quality Assurance & Verification
* **Static Analysis**: All code in `lib/` must adhere strictly to Dart and Flutter analysis rules (`analysis_options.yaml`).
* To verify:
  ```bash
  flutter analyze
  ```
  *Current status: 0 issues found.*
