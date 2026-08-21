_Last Modified: 2026-08-07_

# 03. Engineering Overview

This document provides a comprehensive high-level summary of the Quest codebase. It is designed to give an external agent or new engineer complete context about the project's architecture, technology stack, platform domains, and current development status.

## 1. Executive Summary & Product Vision
**Quest** is a Flutter multiplatform **Social Operating System** for real-world connection. It gamifies community participation — members earn XP, level up, complete daily quests, RSVP to events, and engage in live audio stage rooms.

- **Philosophy:** "Participation over attention." Bridging the gap between online communities and real-world action.
- **Platforms:** Android, iOS, Web, Windows, macOS, Linux.
- **Current Status:** Production Prototype. Core Platform Layers implemented. Supabase backend is configured but some features are temporarily relying on offline bypass.

## 2. Technology Stack & Architecture
- **Framework:** Flutter SDK (`^3.12.0`)
- **Language:** Dart (`>=3.0.0`)
- **State Management:** `flutter_riverpod` (`^3.4.2`) - specifically using `AsyncNotifier` and `Notifier` for reactive state.
- **Routing:** `go_router` (`^17.3.0`) - Declarative, URL-aware routing.
- **Backend / Database:** `supabase_flutter` (`^2.16.0`) - Used for Auth, Postgres DB, real-time channels. (Currently configured via `.env` but offline mode active).
- **Other Key Packages:** `google_fonts`, `flutter_svg`, `cached_network_image`, `shimmer`, `intl`.

## 3. Architectural Patterns
### State Management & Dependency Injection
The application strictly follows a **Domain-Driven Architecture** with the **Repository Pattern**. 
Every module contains a `data/` provider managing immutable state.
- **UI Layer** (`ConsumerWidget`) -> listens to `AsyncNotifier` / `Notifier`
- **Provider Layer** (`AsyncNotifier`) -> handles business logic and state mutation.
- **Repository Layer** -> Abstract interfaces and their Supabase/Mock implementations for data fetching/persistence.

### Routing
Managed by `GoRouter` in `lib/core/router/app_router.dart`.
- Includes an Auth redirect guard (currently configured to bypass directly to `/home` for offline testing).
- Uses `ShellRoute` (`MainShell`) for persistent bottom/side navigation across main tabs.

## 4. Platform Domains Inventory (`lib/features/`)
Unlike traditional apps organized by isolated features, Quest is evolving toward a **Platform Domain** structure. Each domain encapsulates related capabilities.

*(Note: The codebase is currently transitioning to this structure. Some legacy feature directories may still exist during refactoring).*

| Platform Domain | Associated Modules & Providers | Description & Status |
|---|---|---|
| **Identity Layer** | `auth/`, `profile/` | Manages login, signup, XP tracking, leveling logic (baseXp * level^1.4), and gamification streaks. |
| **Interaction Layer** | `messaging/`, `stage/`, `home/` (Feed) | Chat threads, voice notes, live audio rooms, hand raising, and the Experience Feed. |
| **Society Layer** | `communities/`, `events/` | Guilds, categories, search, joining logic, and the RSVP system. |
| **World Layer** | `world/` (combines Radar, Places, Presence) | Proximity check-ins to hubs, persistent digital places, and geographic mapping. *(Refactoring planned)* |
| **Intelligence Layer**| `ai/` (planned cross-cutting) | AI Coach, Recommendation Engine, Moderation. *(Prototype scaffolded)* |
| **Economy Layer** | `economy/` (planned) | Experience Economy: Services, Opportunities, Marketplace, and Wallet. *(Future)* |

## 5. Development Workflow & Rules
- **Living Documentation Rule:** All documentation in `docs/architecture/` must be synchronously updated whenever architectural patterns, providers, routes, or models change.
- **Canonical Vocabulary:** Always adhere to the definitions in `canonical_vocabulary.md` to prevent semantic drift.
- **Zero Warnings:** All changes must pass `flutter analyze` with zero warnings/errors.
- **Design System:** Strict adherence to the `app_colors.dart` design system and `DESIGN.md`. Uses fluid spring animations and haptic feedback.
- **Custom Scripts:** A PowerShell script (`build_apk.ps1`) is used for generating APKs, appending random numeric identifiers, and cleaning up previous builds automatically.

## 6. What Needs to be Covered / Next Steps Discussion Points
- **Architecture Refactoring:** Reorganizing `lib/features/` to physically match the new Platform Domain Model (e.g., consolidating Radar and Places into `lib/features/world/`).
- **Backend Schema Sync:** Replacing mock data implementations with actual Supabase tables/RPCs mapped to the Canonical Vocabulary.
- **Real-time Audio:** Integrating Agora/LiveKit for the `Stage` capability in the Interaction Layer.
- **Geospatial Infrastructure:** Implementing PostGIS geographic queries for the `World` Layer.
