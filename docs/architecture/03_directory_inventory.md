_Last Modified: 2026-08-05_

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
