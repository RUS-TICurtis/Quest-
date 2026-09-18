_Last Modified: 2026-09-18_

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
│   │   ├── services/
│   │   │   └── app_notification_service.dart       # Device-level local notifications (3 channels: uploads/chat/general)
│   │   ├── media/
│   │   │   ├── media_service_gateway.dart          # Routes video/image uploads; Mux→Cloudinary fallback; UploadStatusCallback
│   │   │   ├── media_upload_result.dart            # Upload result model (url, assetId, usedFallback)
│   │   │   ├── media_purpose.dart                  # Enum: feed | chat | profile
│   │   │   ├── media_compressor.dart               # Local video/image compression before upload
│   │   │   └── providers/
│   │   │       ├── mux_service.dart                # Mux direct-upload + fixed 2-phase polling; MuxQuotaException
│   │   │       ├── cloudinary_service.dart         # Cloudinary file/bytes upload (fallback)
│   │   │       └── imagekit_service.dart           # ImageKit image upload (feed images & avatars)
│   │   ├── storage/
│   │   │   ├── local_storage_service.dart          # SharedPreferences persistence (settings, flags, profiles)
│   │   │   ├── local_database_service.dart         # Hive local database (offline feed, member cache, stories)
│   │   │   └── models/
│   │   │       ├── cached_feed_video.dart          # Hive TypeAdapter (typeId 10) for feed caching
│   │   │       ├── cached_member_profile.dart      # Hive TypeAdapter (typeId 11) for member caching
│   │   │       └── cached_story.dart               # Hive TypeAdapter (typeId 12) for story caching
│   │   └── theme/
│   │       ├── app_colors.dart                     # Standardized design system color palette
│   │       ├── app_theme.dart                      # ThemeData configuration (Dark/Light)
│   │       └── quest_icons.dart                    # Custom rounded line icons & symbols
│   ├── shared/
│   │   ├── models/
│   │   │   └── creator_video.dart                  # Creator video domain model
│   │   └── widgets/
│   │       ├── quest_button.dart                   # Standardized interactive button component
│   │       └── expandable_caption.dart             # Rich multi-line expandable caption for feed
│   └── features/
│       ├── identity/
│       │   ├── auth/
│       │   │   ├── data/
│       │   │   │   ├── auth_provider.dart              # Supabase session, user state & auth notifier
│       │   │   │   ├── auth_repository.dart            # Supabase auth queries & Google native token auth
│       │   │   │   └── oauth_server_service.dart       # OAuth 2.1 authorization details & consent grant
│       │   │   └── presentation/
│       │   │       ├── splash_screen.dart              # Launch animation & auth check
│       │   │       ├── landing_screen.dart             # Welcome screen with value proposition
│       │   │       ├── login_screen.dart               # Segmented Sign In / Create Account with Supabase Auth
│       │   │       ├── oauth_consent_screen.dart       # OAuth 2.1 client authorization & scope consent UI
│       │   │       └── onboarding_screen.dart          # Multi-step archetype & interest selection
│       │   ├── leaderboard/
│       │   │   ├── data/
│       │   │   │   ├── leaderboard_provider.dart       # Season standings & archetype rankings
│       │   │   │   └── leaderboard_repository.dart     # Supabase leaderboard queries
│       │   │   └── presentation/
│       │   │       └── leaderboard_screen.dart         # Top-3 podium, rank list & filter tabs
│       │   └── profile/
│       │       ├── data/
│       │       │   ├── user_provider.dart              # Current user profile, XP engine & streak tracking
│       │       │   └── user_repository.dart            # Supabase profile updates & daily quests
│       │       └── presentation/
│       │           ├── profile_screen.dart             # User stats, archetype tags, badges & portal link
│       │           ├── member_profile_screen.dart      # Public peer profiles with connect action
│       │           ├── edit_profile_screen.dart        # Supabase profile editor with avatar upload & bio
│       │           └── settings_screen.dart            # App preferences, notifications, theme toggles
│       ├── interaction/
│       │   ├── connect/
│       │   │   └── presentation/
│       │   │       ├── connect_screen.dart             # Social hub (chat message threads & discovery entry)
│       │   │       └── user_discovery_screen.dart      # Peer discovery with archetype matching & trust scores
│       │   ├── create/
│       │   │   └── presentation/
│       │   │       ├── create_screen.dart              # Camera recording & gallery media ingestion
│       │   │       └── share_experience_screen.dart    # Feed, Story, Community publishing gateway
│       │   ├── explore/
│       │   │   ├── data/
│       │   │   │   ├── global_search_provider.dart     # StateNotifier for multi-entity debounced search
│       │   │   │   └── global_search_repository.dart   # Unified search repository (Users, Quests, Events, Guilds)
│       │   │   └── presentation/
│       │   │       ├── explore_screen.dart             # Discover feed with hero carousels & category chips
│       │   │       ├── user_search_screen.dart         # Finishd-styled glassmorphic Global Search screen
│       │   │       └── widgets/
│       │   │           └── discover_components.dart    # Search cards, chips & trending widgets
│       │   ├── feed/
│       │   │   ├── controller/
│       │   │   │   └── feed_controller.dart            # PageController & index state
│       │   │   ├── data/
│       │   │   │   ├── feed_provider.dart              # Feed videos stream & engagement state
│       │   │   │   └── feed_repository.dart            # Supabase videos table queries
│       │   │   └── presentation/
│       │   │       └── feed_screen.dart                # Fullscreen vertical TikTok-style video feed
│       │   ├── home/
│       │   │   ├── data/
│       │   │   │   ├── stories_provider.dart           # Story models, state notifier & active stories
│       │   │   │   └── stories_repository.dart         # Supabase stories queries & mutations
│       │   │   └── presentation/
│       │   │       ├── home_screen.dart                # Command Center (XP, Streak, Stories, Quests)
│       │   │       ├── story_creator/
│       │   │       │   └── story_creator_screen.dart   # Live text/media story publishing
│       │   │       └── widgets/
│       │   │           ├── stories_bar.dart            # Horizontal story avatars with live ring indicators
│       │   │           ├── story_viewer_modal_v2.dart  # StoryViewer v2 with synchronized video/photo durations
│       │   │           ├── my_status_modal.dart        # WhatsApp-style status management & user story list
│       │   │           └── level_up_dialog.dart        # Celebration modal with confetti & haptics
│       │   ├── messaging/
│       │   │   ├── data/
│       │   │   │   ├── chat_provider.dart              # Conversation threads & message dispatches
│       │   │   │   └── chat_repository.dart            # Supabase realtime stream & offline outbox
│       │   │   └── presentation/
│       │   │       ├── app_emoji_picker.dart           # Themed emoji picker sheet
│       │   │       ├── chat_screen.dart                # 1:1 Telegram replica chat screen with v_chat_bubbles
│       │   │       ├── messages_screen.dart            # Telegram chat list with category tabs & status ticks
│       │   │       ├── whatsapp_text_field.dart        # WhatsApp-style chat composer with attachments
│       │   │       └── widgets/
│       │   │           ├── link_preview_bubble.dart    # Rich OpenGraph-style preview card
│       │   │           ├── telegram_wallpaper.dart     # Authentic Telegram textured doodle canvas painter
│       │   │           └── voice_note_bubble.dart      # Tap-to-seek waveform scrubber with synced playback
│       │   ├── notifications/
│       │   │   └── presentation/
│       │   │       └── notifications_screen.dart       # Filterable activity & system alerts inbox
│       │   └── stage/
│       │       ├── data/
│       │       │   ├── stage_provider.dart             # Live room, speaker roster, mic toggle & reactions
│       │       │   └── stage_repository.dart           # Stage room repository
│       │       └── presentation/
│       │           └── stage_screen.dart               # Audio room with sinusoidal equalizer & physics emojis
│       ├── society/
│       │   ├── communities/
│       │   │   ├── data/
│       │   │   │   ├── communities_provider.dart       # Guilds, join state, and category filtering
│       │   │   │   ├── communities_repository.dart     # Supabase communities table queries
│       │   │   │   ├── community_post.dart             # Community discussion post data model
│       │   │   │   └── community_posts_provider.dart   # Community discussion posts notifier
│       │   │   └── presentation/
│       │   │       ├── communities_screen.dart         # Explore guilds, categories, and active hubs
│       │   │       ├── community_detail_screen.dart    # Channels, announcements, and member rosters
│       │   │       └── widgets/
│       │   │           └── community_post_card.dart    # Feed card for community post discussions
│       │   ├── events/
│       │   │   ├── data/
│       │   │   │   ├── events_provider.dart            # Events, RSVP management, and filter states
│       │   │   │   └── events_repository.dart          # Supabase events table queries
│       │   │   └── presentation/
│       │   │       ├── events_screen.dart              # Event discovery & filter chips
│       │   │       └── event_detail_screen.dart        # Hero banner, RSVP (+30 XP), tickets, share modal
│       │   └── organization/
│       │       └── presentation/
│       │           ├── organization_dashboard_screen.dart # Admin metrics, member analytics & quick actions
│       │           └── widgets/
│       │               ├── create_event_sheet.dart     # Modal form for hosting events
│       │               └── post_announcement_sheet.dart# Modal for broadcasting updates
│       ├── world/
│       │   └── radar/
│       │       ├── data/
│       │       │   ├── radar_provider.dart             # Proximity hubs, member blips, and check-in state
│       │       │   └── radar_repository.dart           # Radar nodes & proximity queries
│       │       └── presentation/
│       │           └── radar_screen.dart               # High-tech HUD radar canvas, sweep animation & pings
│       ├── economy/
│       │   ├── commerce/
│       │   │   └── data/
│       │   │       ├── commerce_models.dart            # Marketplace listing & transaction models
│       │   │       └── commerce_provider.dart          # Commerce listings & purchase actions
│       │   ├── opportunities/
│       │   │   └── data/
│       │   │       ├── opportunity_models.dart         # Jobs, internships & bounty models
│       │   │       └── opportunities_provider.dart     # Opportunity filters & application notifier
│       │   └── wallet/
│       │       └── data/
│       │           ├── wallet_models.dart              # Quest Coins & real balance transaction models
│       │           └── wallet_provider.dart            # Wallet balance & transaction history notifier
│       └── intelligence/                               # Future AI personal coach, community agents & moderation
├── supabase/
│   ├── functions/                                      # 37 Deno TypeScript Edge Functions
│   └── migrations/                                     # 10 PostgreSQL schema migrations & seed files
├── CODEBASE_DOCUMENTATION.md                           # Master technical architecture & living manual
├── DESIGN.md                                           # Core product design principles & specifications
└── pubspec.yaml                                        # Manifest & package dependencies
```

---
