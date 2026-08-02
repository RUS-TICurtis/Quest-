import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/story_creator/story_creator_screen.dart';
import '../../features/communities/presentation/communities_screen.dart';
import '../../features/communities/presentation/community_detail_screen.dart';
import '../../features/events/presentation/events_screen.dart';
import '../../features/events/presentation/event_detail_screen.dart';
import '../../features/messaging/presentation/messages_screen.dart';
import '../../features/messaging/presentation/chat_screen.dart';
import '../../features/organization/presentation/organization_dashboard_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/member_profile_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/stage/presentation/stage_screen.dart';
import '../../features/radar/presentation/radar_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../shell/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth flow — no nav shell
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/landing',
      name: 'landing',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Main app shell — persistent bottom/side nav
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/communities',
          name: 'communities',
          builder: (context, state) => const CommunitiesScreen(),
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
          builder: (context, state) => const EventsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'event_detail',
              builder: (context, state) => EventDetailScreen(
                eventId: state.pathParameters['id'] ?? '1',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          builder: (context, state) => const MessagesScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'chat',
              builder: (context, state) => ChatScreen(
                threadId: state.pathParameters['id'] ?? '1',
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
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
      path: '/organization',
      name: 'organization',
      builder: (context, state) => const OrganizationDashboardScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/stage/:id',
      name: 'stage',
      builder: (context, state) => StageScreen(
        stageId: state.pathParameters['id'] ?? 'stage_1',
      ),
    ),
    GoRoute(
      path: '/radar',
      name: 'radar',
      builder: (context, state) => const RadarScreen(),
    ),
    GoRoute(
      path: '/create-story',
      name: 'create_story',
      builder: (context, state) => const StoryCreatorScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      name: 'leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
  ],
);
