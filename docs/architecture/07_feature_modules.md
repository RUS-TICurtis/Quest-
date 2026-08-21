_Last Modified: 2026-08-06_

# 7. Feature Modules

## Feature Inventory

| Feature | Path | Status | Backend |
|---|---|---|---|
| **Auth** | `lib/features/auth/` | ✅ Complete | Supabase Auth |
| **Profile / XP** | `lib/features/profile/` | ✅ Complete | `profiles`, `daily_quests` tables |
| **Home / Stories** | `lib/features/home/` | ✅ Complete | `stories` table (fallback to mock) |
| **Events** | `lib/features/events/` | ✅ Complete | `events` table |
| **Communities** | `lib/features/communities/` | ✅ Complete | `communities` table |
| **Messaging / Chat** | `lib/features/messaging/` | 🟡 Mock Data | `chat_messages` table pending schema |
| **Stage (Audio)** | `lib/features/stage/` | 🟡 Mock Data | Agora/LiveKit not yet integrated |
| **Radar** | `lib/features/radar/` | 🟡 Partial | `radar_nodes` ✅, `radar_members` pending PostGIS |
| **Leaderboard** | `lib/features/leaderboard/` | 🟡 Partial | `leaderboard` ✅, guilds are mock |
| **Organization** | `lib/features/organization/` | 🟡 Scaffold | Host/admin portal |

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
| `authProvider` | `Notifier<AuthState>` | `signIn()`, `signOut()`, `signUp()` |
| `userProvider` | `AsyncNotifier<UserState>` | `addXp()`, `toggleQuest()`, `updateName()`, `toggleRsvp()` |
| `eventsProvider` | `AsyncNotifier<EventsState>` | `toggleRsvp()`, `addEvent()`, `setFilter()` |
| `communitiesProvider` | `AsyncNotifier<CommunitiesState>` | `toggleJoin()`, `addCommunity()`, `setCategory()`, `setSearchQuery()` |
| `chatProvider` | `StreamNotifier<ChatState> (Supabase Realtime)` | `sendMessage()`, `sendVoiceNote()`, `markThreadRead()` |
| `stageProvider(id)` | `AsyncNotifier<StageState>` (family) | `toggleMic()`, `toggleHandRaise()`, `sendReaction()` |
| `radarProvider` | `AsyncNotifier<RadarState>` | `selectHub()`, `checkInToHub()` |
| `leaderboardProvider` | `AsyncNotifier<LeaderboardState>` | `setTab()`, `setArchetype()` |
| `storiesProvider` | `AsyncNotifier<List<StoryItem>>` | `addStory()`, `markAsSeen()` |

## Gamification System

XP and leveling logic lives entirely in `UserNotifier`:
- Each level requires `baseXp * level^1.4` XP (exponential curve)
- Daily quests can be toggled on/off (XP is reverted on un-toggle)
- Streak is tracked as consecutive days with at least one quest completed
- Level-up triggers a dialog via `LevelUpDialog` widget (`lib/features/home/presentation/widgets/level_up_dialog.dart`)
