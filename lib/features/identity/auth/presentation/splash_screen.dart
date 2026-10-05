import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/shared/widgets/quest_button.dart';

/// Pure presentation of the boot state.
///
/// It does NOT navigate and does NOT use timers: `appRouterProvider`'s redirect
/// is the single routing authority and moves away from `/` as soon as the
/// session + profile state is known. This screen only shows progress, or a
/// retry affordance when the profile could not be loaded.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMember = ref.watch(authProvider).accessLevel == AccessLevel.member;
    final profile = ref.watch(userProvider);
    final failed = isMember && profile.hasError && !profile.hasValue;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          Positioned(
            top: size.height * 0.1,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                color: context.colors.questBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: context.colors.auroraPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Semantics(
              label: failed ? 'Could not load Quest' : 'Loading Quest',
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.colors.questBlue,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.questBlue.withValues(
                              alpha: 0.5,
                            ),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: context.colors.textPrimary,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Quest',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (failed) ...[
                      Text(
                        "Couldn't load your profile.\nCheck your connection and try again.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      QuestButton(
                        label: 'Retry',
                        icon: Icons.refresh,
                        onPressed: () => ref.invalidate(userProvider),
                      ),
                      TextButton(
                        onPressed: () =>
                            ref.read(authProvider.notifier).signOut(),
                        child: Text(
                          'Sign out',
                          style: TextStyle(color: context.colors.textMuted),
                        ),
                      ),
                    ] else if (isMember)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.questBlue,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
