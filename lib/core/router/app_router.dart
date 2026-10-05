import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/auth/presentation/landing_screen.dart';
import 'package:quest/features/identity/auth/presentation/login_screen.dart';
import 'package:quest/features/identity/auth/presentation/signup_screen.dart';
import 'package:quest/features/identity/auth/presentation/oauth_consent_screen.dart';
import 'package:quest/features/identity/auth/presentation/onboarding_screen.dart';
import 'package:quest/features/identity/auth/presentation/splash_screen.dart';
import 'package:quest/features/interaction/home/presentation/home_screen.dart';
import 'package:quest/features/interaction/home/presentation/story_creator/story_creator_screen.dart';
import 'package:quest/features/society/communities/presentation/communities_screen.dart';
import 'package:quest/features/society/communities/presentation/community_detail_screen.dart';
import 'package:quest/features/society/events/presentation/events_screen.dart';
import 'package:quest/features/society/events/presentation/event_detail_screen.dart';
import 'package:quest/features/interaction/connect/presentation/connect_screen.dart';
import 'package:quest/features/interaction/connect/presentation/user_discovery_screen.dart';
import 'package:quest/features/interaction/messaging/presentation/chat_screen.dart';
import 'package:quest/features/society/organization/presentation/organization_dashboard_screen.dart';
import 'package:quest/features/identity/profile/presentation/profile_screen.dart';
import 'package:quest/features/identity/profile/presentation/edit_profile_screen.dart';
import 'package:quest/features/identity/profile/presentation/member_profile_screen.dart';
import 'package:quest/features/identity/profile/presentation/settings_screen.dart';
import 'package:quest/features/interaction/stage/presentation/stage_screen.dart';
import 'package:quest/features/world/radar/presentation/radar_screen.dart';
import 'package:quest/features/identity/leaderboard/presentation/leaderboard_screen.dart';
import 'package:quest/features/interaction/explore/presentation/explore_screen.dart';
import 'package:quest/features/interaction/explore/presentation/user_search_screen.dart';
import 'package:quest/features/interaction/feed/presentation/feed_screen.dart';
import 'package:quest/features/interaction/create/presentation/create_screen.dart';
import 'package:quest/features/interaction/create/presentation/share_experience_screen.dart';
import 'package:quest/features/interaction/notifications/presentation/notifications_screen.dart';
import 'package:quest/core/shell/main_shell.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';

/// A [ChangeNotifier] that wraps Riverpod's [Ref] so [GoRouter] can
/// listen to auth-state changes and re-evaluate its redirect guard.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    // Whenever authProvider emits a new value, notify GoRouter to refresh.
    ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
    // Profile load state decides splash/onboarding/home. Only the fields the
    // redirect reads are compared so XP ticks don't re-run redirects.
    ref.listen<AsyncValue<UserState>>(userProvider, (prev, next) {
      String key(AsyncValue<UserState>? v) =>
          '${v?.isLoading}-${v?.hasValue}-${v?.hasError}-${v?.value?.onboardingCompleted}';
      if (key(prev) != key(next)) notifyListeners();
    });
  }
}

/// Routes a guest (anonymous session) may NOT open. They get an upgrade
/// prompt (sign in / sign up) and return here afterwards. Server-side RLS and
/// edge functions enforce the same rule independently.
const _guestRestrictedPrefixes = <String>[
  '/create',
  '/connect',
  '/edit-profile',
  '/organization',
  '/create-story',
  '/share-experience',
];

/// Only same-app absolute paths are accepted as post-login targets.
String? _safeRedirect(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (!raw.startsWith('/') || raw.startsWith('//')) return null;
  return raw;
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    // refreshListenable ensures redirect fires on every auth state change,
    // including spontaneous session expiry and sign-out, without recreating the router.
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isSplash = loc == '/';
      final isLanding = loc == '/landing';
      final isLogin = loc == '/login';
      final isSignup = loc == '/signup';
      final isOnboarding = loc == '/onboarding';
      final isConsent = loc == '/oauth/consent';
      final isEntryRoute = isSplash || isLanding || isLogin || isSignup;
      final target = _safeRedirect(state.uri.queryParameters['redirect']);

      switch (auth.accessLevel) {
        case AccessLevel.unauthenticated:
          if (isConsent) {
            final back = Uri.encodeComponent(state.uri.toString());
            return '/login?redirect=$back';
          }
          if (isLanding || isLogin || isSignup) return null;
          return '/landing';

        case AccessLevel.guest:
          if (isSplash || isLanding || isOnboarding) return '/home';
          if (isLogin || isSignup) return null; // upgrade path
          if (_guestRestrictedPrefixes.any(loc.startsWith)) {
            return '/login?redirect=${Uri.encodeComponent(state.uri.toString())}';
          }
          return null;

        case AccessLevel.member:
          final profile = ref.read(userProvider);
          // Destination depends on the profile: hold at the splash until the
          // backend has answered (loading or failed — splash renders retry).
          if (!profile.hasValue) return isSplash ? null : '/';
          final done = profile.requireValue.onboardingCompleted;
          if (!done) return isOnboarding ? null : '/onboarding';
          if (isEntryRoute || isOnboarding) return target ?? '/home';
          return null;
      }
    },
    routes: [
      // Auth flow — no nav shell
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => SplashScreen(),
      ),
      GoRoute(
        path: '/landing',
        name: 'landing',
        builder: (context, state) => LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/oauth/consent',
        name: 'oauth_consent',
        builder: (context, state) => OAuthConsentScreen(
          authorizationId: state.uri.queryParameters['authorization_id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => OnboardingScreen(),
      ),

      // Main app shell — persistent bottom/side nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => HomeScreen(),
          ),
          GoRoute(
            path: '/feed',
            name: 'feed',
            builder: (context, state) => FeedScreen(),
          ),
          GoRoute(
            path: '/explore',
            name: 'explore',
            builder: (context, state) => ExploreScreen(),
            routes: [
              GoRoute(
                path: 'search',
                name: 'user_search',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => UserSearchScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/create',
            name: 'create',
            builder: (context, state) => CreateScreen(),
          ),
          GoRoute(
            path: '/connect',
            name: 'connect',
            builder: (context, state) => ConnectScreen(),
            routes: [
              GoRoute(
                path: 'user_discovery',
                name: 'user_discovery',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => UserDiscoveryScreen(),
              ),
              GoRoute(
                path: ':id',
                name: 'chat',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) =>
                    ChatScreen(threadId: state.pathParameters['id'] ?? '1'),
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => ProfileScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'member_profile',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => MemberProfileScreen(
                  memberId: state.pathParameters['id'] ?? 'u_curr',
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/communities',
        name: 'communities',
        builder: (context, state) => CommunitiesScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'community_detail',
            builder: (context, state) => CommunityDetailScreen(
              communityId: state.pathParameters['id'] ?? '1',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => EventsScreen(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'event_detail',
            builder: (context, state) =>
                EventDetailScreen(eventId: state.pathParameters['id'] ?? '1'),
          ),
        ],
      ),
      GoRoute(
        path: '/organization',
        name: 'organization',
        builder: (context, state) => OrganizationDashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => SettingsScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        name: 'edit_profile',
        builder: (context, state) => EditProfileScreen(),
      ),
      GoRoute(
        path: '/stage/:id',
        name: 'stage',
        builder: (context, state) =>
            StageScreen(stageId: state.pathParameters['id'] ?? 'stage_1'),
      ),
      GoRoute(
        path: '/radar',
        name: 'radar',
        builder: (context, state) => RadarScreen(),
      ),
      GoRoute(
        path: '/create-story',
        name: 'create_story',
        builder: (context, state) => StoryCreatorScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => LeaderboardScreen(),
      ),
      GoRoute(
        path: '/share-experience',
        name: 'share_experience',
        builder: (context, state) =>
            ShareExperienceScreen(mediaPath: state.extra as String?),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
