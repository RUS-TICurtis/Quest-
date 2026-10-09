_Last Modified: 2026-10-09_

# 5. Navigation & Routing

## Router: GoRouter 17.x

GoRouter is initialized via `appRouterProvider` in `lib/core/router/app_router.dart`.

## Key Features

- **`refreshListenable` & Singleton Router**: A `_RouterNotifier extends ChangeNotifier` wraps Riverpod's `authProvider` and calls `notifyListeners()` on auth changes. `appRouterProvider` uses `ref.read` (never `ref.watch(authProvider)`), preventing GoRouter from being recreated and resetting back to `/` (splash) whenever auth state changes.
- **Auth Guard**: The `redirect` function checks `authState.isAuthenticated` to enforce protected/unprotected routes.
- **Shell Route**: `ShellRoute` wraps main app screens with `MainShell` (persistent bottom nav / navigation rail). On the Create tab (`/create`), the bottom navigation bar is suppressed dynamically to ensure an edge-to-edge camera viewfinder without navigation collisions.

## Route Catalog

| Path | Name | Screen | Auth Required |
|---|---|---|---|
| `/` | `splash` | `SplashScreen` | No |
| `/landing` | `landing` | `LandingScreen` | No |
| `/login` | `login` | `LoginScreen` | No |
| `/onboarding` | `onboarding` | `OnboardingScreen` | No |
| `/home` | `home` | `HomeScreen` | Yes (Shell) |
| `/feed` | `feed` | `FeedScreen` | Yes (Shell) |
| `/create` | `create` | `CreateScreen` | Yes (Shell, bottom nav bar suppressed) |
| `/communities` | `communities` | `CommunitiesScreen` | Yes (Shell) |
| `/communities/:id` | `community_detail` | `CommunityDetailScreen` | Yes (Shell) |
| `/events` | `events` | `EventsScreen` | Yes (Shell) |
| `/events/:id` | `event_detail` | `EventDetailScreen` | Yes (Shell) |
| `/messages` | `messages` | `MessagesScreen` | Yes (Shell) |
| `/messages/:id` | `chat` | `ChatScreen` | Yes (Shell) |
| `/profile` | `profile` | `ProfileScreen` | Yes (Shell) |
| `/profile/:id` | `member_profile` | `MemberProfileScreen` | Yes (Shell) |
| `/profile/edit` | `edit_profile` | `EditProfileScreen` | Yes (no Shell) |
| `/oauth/consent` | `oauth_consent` | `OAuthConsentScreen` | Yes (no Shell, forwards to /login?redirect=...) |
| `/settings` | `settings` | `SettingsScreen` | Yes (no Shell) |
| `/organization` | `organization` | `OrganizationDashboardScreen` | Yes (no Shell) |
| `/stage/:id` | `stage` | `StageScreen(stageId)` | Yes (no Shell) |
| `/radar` | `radar` | `RadarScreen` | Yes (no Shell) |
| `/create-story` | `create_story` | `StoryCreatorScreen` | Yes (no Shell) |
| `/leaderboard` | `leaderboard` | `LeaderboardScreen` | Yes (no Shell) |
| `/share-experience` | `share_experience` | `ShareExperienceScreen(payload)` | Yes (no Shell, accepts `CreateSubmissionPayload`) |

## Auth Redirect Logic

```
if (!isAuth && isConsent) → /login?redirect=<target>
if (!isAuth && !isAuthRoute) → /landing
if (isAuth && (isLanding || isLogin)) → redirectTarget ?? /home
else → null (no redirect)
```

## Shell Navigation

`MainShell` (`lib/core/shell/main_shell.dart`) uses:
- `BottomNavigationBar` when `MediaQuery.width < 600` (mobile). The navigation bar explicitly displays text labels for each tab.
- `NavigationRail` when `MediaQuery.width >= 600` (tablet/desktop)

Navigation destinations: Home, Explore, Create, Connect, Profile.
There is no global `AppBar` on mobile; the app relies on the `BottomNavigationBar` and custom app bars within individual screens (like the transparent `AppBar` in `ProfileScreen` for Leaderboard and Settings). Sub-routes (e.g., Chat, Search) use `parentNavigatorKey` to push above the shell and hide the navigation bar.
- **Mission Control Gestures**: The Home tab serves as Mission Control. The Home icon on the navigation bar is wrapped in a `GestureDetector` that routes to the full-screen Experience Feed (`/feed`) on double-tap or swipe gestures.

---
## Redirect Contract (updated 2026-10-05)
_Last Modified: 2026-10-05_

`appRouterProvider` redirect is the **only** navigation authority (the splash screen no longer navigates). It is re-evaluated when `authProvider` or the relevant fields of `userProvider` (loading/value/error/`onboardingCompleted`) change.

| AccessLevel | Behaviour |
|---|---|
| `unauthenticated` | only `/landing`, `/login`, `/signup`; everything else -> `/landing`; `/oauth/consent` -> `/login?redirect=` |
| `guest` (anonymous session) | splash/landing/onboarding -> `/home`; login/signup allowed (upgrade); `/create`, `/connect*`, `/edit-profile`, `/organization`, `/create-story`, `/share-experience` -> `/login?redirect=<target>` |
| `member` | profile not loaded -> hold on `/` (splash shows loading / retry); onboarding incomplete -> `/onboarding`; complete + on entry/onboarding route -> `redirect` param (same-app absolute paths only) or `/home` |
