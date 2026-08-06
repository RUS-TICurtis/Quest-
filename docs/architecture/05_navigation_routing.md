_Last Modified: 2026-08-06_

# 5. Navigation & Routing

## Router: GoRouter 17.x

GoRouter is initialized via `appRouterProvider` in `lib/core/router/app_router.dart`.

## Key Features

- **`refreshListenable`**: A `_RouterNotifier extends ChangeNotifier` wraps Riverpod's `authProvider` and calls `notifyListeners()` on every auth state change. This guarantees GoRouter's `redirect` fires immediately on sign-in, sign-out, and session expiry — not just on navigation events.
- **Auth Guard**: The `redirect` function checks `authState.isAuthenticated` to enforce protected/unprotected routes.
- **Shell Route**: `ShellRoute` wraps main app screens with `MainShell` (persistent bottom nav / navigation rail).

## Route Catalog

| Path | Name | Screen | Auth Required |
|---|---|---|---|
| `/` | `splash` | `SplashScreen` | No |
| `/landing` | `landing` | `LandingScreen` | No |
| `/onboarding` | `onboarding` | `OnboardingScreen` | No |
| `/home` | `home` | `HomeScreen` | Yes (Shell) |
| `/communities` | `communities` | `CommunitiesScreen` | Yes (Shell) |
| `/communities/:id` | `community_detail` | `CommunityDetailScreen` | Yes (Shell) |
| `/events` | `events` | `EventsScreen` | Yes (Shell) |
| `/events/:id` | `event_detail` | `EventDetailScreen` | Yes (Shell) |
| `/messages` | `messages` | `MessagesScreen` | Yes (Shell) |
| `/messages/:id` | `chat` | `ChatScreen` | Yes (Shell) |
| `/profile` | `profile` | `ProfileScreen` | Yes (Shell) |
| `/profile/:id` | `member_profile` | `MemberProfileScreen` | Yes (Shell) |
| `/settings` | `settings` | `SettingsScreen` | Yes (no Shell) |
| `/organization` | `organization` | `OrganizationDashboardScreen` | Yes (no Shell) |
| `/stage/:id` | `stage` | `StageScreen(stageId)` | Yes (no Shell) |
| `/radar` | `radar` | `RadarScreen` | Yes (no Shell) |
| `/create-story` | `create_story` | `StoryCreatorScreen` | Yes (no Shell) |
| `/leaderboard` | `leaderboard` | `LeaderboardScreen` | Yes (no Shell) |

## Auth Redirect Logic

```
if (!isAuth && !isAuthRoute) → /landing
if (isAuth && (isLanding || isOnboarding)) → /home
else → null (no redirect)
```

## Shell Navigation

`MainShell` (`lib/core/shell/main_shell.dart`) uses:
- `BottomNavigationBar` when `MediaQuery.width < 600` (mobile)
- `NavigationRail` when `MediaQuery.width >= 600` (tablet/desktop)

Navigation destinations: Home, Communities, Events, Messages, Profile
