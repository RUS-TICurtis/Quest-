import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/auth/presentation/landing_screen.dart';
import 'package:quest/features/identity/auth/presentation/login_screen.dart';
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
import 'package:quest/core/shell/main_shell.dart';

/// A [ChangeNotifier] that wraps Riverpod's [Ref] so [GoRouter] can
/// listen to auth-state changes and re-evaluate its redirect guard.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    // Whenever authProvider emits a new value, notify GoRouter to refresh.
    ref.listen<AuthState>(authProvider, (prev, next) => notifyListeners());
  }
}

final _routerNotifierProvider = Provider<_RouterNotifier>((ref) {
  return _RouterNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(_routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    // refreshListenable ensures redirect fires on every auth state change,
    // including spontaneous session expiry and sign-out, without recreating the router.
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final isSplash = loc == '/';
      final isLanding = loc == '/landing';
      final isLogin = loc == '/login';
      final isOnboarding = loc == '/onboarding';
      final isConsent = loc == '/oauth/consent';
      final isAuthRoute = isSplash || isLanding || isLogin || isOnboarding;

      // If user is not authenticated and attempts to access consent screen,
      // redirect to /login with target return parameter
      if (!isAuth && isConsent) {
        final target = Uri.encodeComponent(state.uri.toString());
        return '/login?redirect=$target';
      }

      // If user is not authenticated and attempts to access protected routes, redirect to /landing
      if (!isAuth && !isAuthRoute) {
        return '/landing';
      }

      // If authenticated and on landing or login, redirect to home or preserved redirect target
      if (isAuth && (isLanding || isLogin)) {
        final redirectTarget = state.uri.queryParameters['redirect'];
        if (redirectTarget != null && redirectTarget.isNotEmpty) {
          return redirectTarget;
        }
        return '/home';
      }

      return null;
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
                path: ':id',
                name: 'chat',
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
        path: '/profile/edit',
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
        builder: (context, state) => ShareExperienceScreen(
          mediaPath: state.extra as String?,
        ),
      ),
    ],
  );
});
