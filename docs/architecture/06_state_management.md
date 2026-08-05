_Last Modified: 2026-08-05_

## 6. State Management Architecture (Riverpod 3.x)

Every feature module contains a dedicated `data/` provider managing immutable state through an `AsyncNotifier` or `Notifier`. The codebase is actively transitioning to the Repository Pattern backed by `AsyncNotifier` to prepare for backend integrations.

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

#
