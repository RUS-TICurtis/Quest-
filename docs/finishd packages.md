# Viable Finishd Packages

This document catalogs every single package used in the **Finishd** codebase, including those currently active in the `pubspec.yaml` and those that were documented as either removed, tested, or planned for future updates.

## 📦 Currently Active Dependencies (from pubspec.yaml)

### UI & Icons
- `cupertino_icons` (^1.0.8)
- `font_awesome_flutter` (^11.0.0)
- `lucide_icons_flutter` (^3.1.14+2)
- `sizer` (^3.1.3)
- `v_chat_bubbles` (^1.2.7) - WhatsApp-style chat bubbles
- `shimmer` (^3.0.0) - Loading animations
- `emoji_picker_flutter` (^4.4.0)
- `dash_chat_2` (any) - Chat UI
- `flutter_chatflow` (^2.0.2) - Chatflow like WhatsApp
- `spoiler_widget` (1.0.25) - Spoilers for text and media
- `flutter_welcome_kit` (local path: `lib/packages/flutter_welcome_kit`)

### API & Networking
- `http` (^1.2.0)
- `dio` (^5.4.0)
- `tmdb_api` (^2.2.3) - The Movie Database API
- `cached_network_image` (^3.4.1)
- `flutter_cache_manager` (^3.4.1)

### State Management & Architecture
- `provider` (^6.1.2)
- `go_router` (^17.0.1)

### Firebase & Supabase
- `firebase_core` (any)
- `firebase_messaging` (any) - FCM Push Notifications
- `flutter_local_notifications` (^22.0.1)
- `supabase_flutter` (^2.8.0)

### Utilities & Services
- `url_launcher` (^6.3.0)
- `share_plus` (^13.1.0)
- `connectivity_plus` (^7.0.0)
- `intl` (^0.20.0)
- `uuid` (^4.5.1)
- `logger` (^2.7.0)
- `crypto` (^3.0.7)
- `collection` (^1.19.1)
- `workmanager` (^0.9.0+3) - Background tasks
- `flutter_dotenv` (^6.0.0)
- `app_links` (any) - Deep linking
- `wakelock_plus` (^1.5.2)

### Auth
- `google_sign_in` (^7.2.0)
- `sign_in_with_apple` (any)

### Storage & Local DB
- `shared_preferences` (^2.5.4)
- `sqflite` (^2.4.2)
- `path` (^1.9.1)
- `path_provider` (any)
- `hive` (any)
- `hive_flutter` (^1.1.0)
- `objectbox` (^5.1.0) - Offline-first feed cache
- `objectbox_flutter_libs` (any)

### Media (Video, Images, Editing)
- `visibility_detector` (^0.4.0+2) - Used for auto-play/pause in feeds
- `image_picker` (^1.2.1)
- `crop_image` (1.0.17)
- `pro_video_editor` (^1.22.0)
- `pro_image_editor` (^12.5.1)
- `v_video_compressor` (^2.0.0)
- `video_player` (^2.11.1)
- `chewie` (^1.13.0)
- `adaptive_video_player` (^1.2.2)
- `flutter_video_caching` (^1.1.3)

### AI
- `google_generative_ai` (^0.4.5)

### Dev Dependencies & Tooling
- `flutter_native_splash` (^2.4.0)
- `flutter_launcher_icons` (^0.14.3)
- `build_runner` (^2.4.0)
- `objectbox_generator` (^5.1.0)
- `flutter_lints` (^6.0.0)

---

## 🗑️ Documented Past/Planned/Removed Packages

These packages were discovered in the `0future updates and packages.txt`, `finishd_project_documentation.md`, or referenced in code comments, representing features tested or planned for Finishd.

### Social & Chat Enhancements
- `whatsapp_chat_sdk` (^1.0.1) - WhatsApp 1:1 clone for chatlist/screen
- `voice_note_kit` (^1.3.3) - For voice notes
- `flutter_link_previewer` (^4.2.0) - Link previews in chat
- `secure_application` (^4.1.0) - Blurs/prevents screenshots for chat screen

### Stories & Feeds
- `flutter_story_presenter` (^1.0.7) - For stories
- `story_view` (^0.16.6) - For stories
- `marvelous_carousel` (^0.0.16) - For carousel effects on categories items

### UI/UX Polish
- `smart_keyboard_insets` (^0.0.1) - Smooth UI transitions for list scrolling when keyboard opens/closes
- `hidable` (^1.0.6) - Hides floating widgets on scroll
- `text_editor` (^0.7.0) - Image and video overlaying caption text font type editor

### Video Stack Alternatives (Removed/Migrated)
- `media_kit` - Removed. Documented as causing native FFI crashes (`[anon:FfiCallbackMetadata::TrampolinePage]`) during Hot Restarts when background threads hit dead pointers. Migrated to `video_player` + `chewie`.
- `cached_video_player_plus` - Mentioned as a legacy MP4 cache solution in `pubspec.yaml` comments before moving to `video_player` + HLS.
- `youtube_player_flutter` (9.0.3) - Used for YouTube trailer playback.
- `youtube_explode_dart` (2.5.3) - Used for YouTube video URL extraction for the feed.
