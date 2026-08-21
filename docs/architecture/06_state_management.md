_Last Modified: 2026-08-21_

## 6. State Management Architecture (Riverpod 3.x)

Every feature module contains a dedicated `data/` provider managing immutable state through an `AsyncNotifier` or `Notifier`. The codebase is actively transitioning to the Repository Pattern backed by `AsyncNotifier` to prepare for backend integrations.

> [!IMPORTANT]
> **Strict UI Requirement:** All screens (even static ones) must use `ConsumerWidget` or `ConsumerStatefulWidget` to maintain architectural consistency and prepare for future Riverpod integration. Plain `StatelessWidget` and `StatefulWidget` are prohibited at the screen level.

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Presentation Layer                  │
│       (ConsumerWidget / ConsumerStatefulWidget)             │
└──────────────▲──────────────────────────────┬───────────────┘
               │ watch(provider)              │ read(provider.notifier).action()
┌──────────────┴──────────────────────────────▼───────────────┐
│              Riverpod AsyncNotifier / Notifier              │
│             (State mutation & business logic)               │
└──────────────▲──────────────────────────────┬───────────────┘
               │ reads/persists               │ updates/syncs
┌──────────────┴──────────────────────────────▼───────────────┐
│        Repository Interface (Mock / API Implementation)     │
└──────────────▲──────────────────────────────┬───────────────┘
               │ reads/persists               │ updates/syncs
┌──────────────┴──────────────────────────────▼───────────────┐
│              Data Source (Supabase / Isar DB)               │
└─────────────────────────────────────────────────────────────┘
```

## Implemented Modules (Phase 2 Refactoring)
The following modules strictly adhere to this `AsyncNotifier` + `Repository` pattern:
- **Auth**: `AuthProvider` -> `AuthRepository`
- **Chat**: `ChatProvider` -> `ChatRepository`
- **Radar**: `RadarProvider` -> `RadarRepository`
- **Stage**: `StageProvider` -> `StageRepository`
- **Communities**: `CommunitiesProvider` -> `CommunitiesRepository`
- **Stories**: `StoriesProvider` -> `StoriesRepository`
- **Leaderboard**: `LeaderboardProvider` -> `LeaderboardRepository`

Each model (e.g. `User`, `ChatMessage`, `StageState`) implements `fromJson` and `toJson` serialization for seamless Supabase interoperability.
