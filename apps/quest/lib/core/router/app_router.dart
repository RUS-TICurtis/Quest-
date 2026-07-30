import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/landing_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../shell/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // Auth flow — no nav shell
    GoRoute(
      path: '/',
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
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Communities — Coming Soon', style: TextStyle(color: Colors.white))),
          ),
        ),
        GoRoute(
          path: '/events',
          name: 'events',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Events — Coming Soon', style: TextStyle(color: Colors.white))),
          ),
        ),
        GoRoute(
          path: '/messages',
          name: 'messages',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Messages — Coming Soon', style: TextStyle(color: Colors.white))),
          ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
