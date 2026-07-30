# Quest

> **The Social Operating System for Real-World Connection.**

Build communities. Discover events. Level up your life.

---

## Stack

| Layer | Technology |
|---|---|
| **Frontend (all platforms)** | Flutter 3.x |
| **Backend / Database** | Supabase (PostgreSQL) |
| **Auth** | Supabase Auth (Email, Google, Apple) |
| **Storage** | Supabase Storage |
| **Realtime** | Supabase Realtime |
| **State Management** | Riverpod |
| **Navigation** | GoRouter |
| **Local Cache / DB** | Isar |
| **AI** | OpenRouter (OpenAI, Gemini, Anthropic) |
| **Push Notifications** | Firebase Cloud Messaging |
| **Maps** | OpenStreetMap |
| **Monitoring** | Sentry |
| **Analytics** | PostHog |

## Platforms

One codebase. All platforms.

- ✅ Android
- ✅ iOS
- ✅ Web (Flutter Web)
- ✅ Windows
- ✅ macOS
- ✅ Linux

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (stable channel)
- Dart 3.x

> **⚠️ Important:** Flutter does not support special characters in the project path.
> Clone this repository to a path **without** special characters (e.g., `!`, `#`, `$`).
> 
> ✅ Good: `C:\Users\YourName\Projects\Quest`  
> ❌ Bad:  `C:\Users\YourName\Documents\_Github\Quest!`

### Run the app

```bash
cd apps/quest
flutter pub get
flutter run
```

### Run on a specific platform

```bash
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run -d chrome     # Web (Chrome)
flutter run               # Connected Android or iOS device
```

---

## Architecture

```
apps/quest/lib/
├── main.dart                     # Entry point
├── app.dart                      # MaterialApp.router, theme
├── core/
│   ├── theme/                    # Color tokens, dark theme
│   ├── router/                   # GoRouter configuration
│   └── shell/                    # Responsive nav shell
├── features/
│   ├── auth/                     # Landing, onboarding
│   ├── home/                     # Dashboard, XP, AI Coach
│   ├── profile/                  # Identity, reputation
│   ├── communities/              # Community list + detail
│   ├── events/                   # Event discovery + RSVP
│   ├── messaging/                # Inbox + chat
│   └── notifications/            # Notification center
└── shared/
    ├── widgets/                  # Design system widgets
    └── models/                   # Shared data models
```

---

## Design System

Full specification in [DESIGN.md](./DESIGN.md).

| Token | Value |
|---|---|
| Quest Blue (Primary) | `#2563EB` |
| Midnight Slate | `#0F172A` |
| Deep Graphite (Surface) | `#111827` |
| Near Black (Background) | `#030712` |
| Aurora Purple (Accent) | `#7C3AED` |
| Gold (XP) | `#FBBF24` |
| Emerald (Success) | `#10B981` |

**Font:** Inter (via `google_fonts`)

---

## License

All rights reserved. Quest is a private project.
# quest

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
