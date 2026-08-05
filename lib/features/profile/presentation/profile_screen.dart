import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = (ref.watch(userProvider).value ?? UserState.initial());

    final stats = [
      {'label': 'Level', 'value': '${userState.level}'},
      {'label': 'XP', 'value': '${userState.currentXp}'},
      {'label': 'Streak', 'value': '${userState.streak}d'},
      {'label': 'Badges', 'value': '${userState.badges.length}'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: AppColors.gold),
            tooltip: 'Season Leaderboard',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/leaderboard');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Name
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.questBlue,
                        child: Text(
                          userState.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.emerald,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.background, width: 2.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userState.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Lvl ${userState.level} ${userState.archetypes.join(" & ")}',
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: stats
                    .map(
                      (s) => Expanded(
                        child: Column(
                          children: [
                            Text(
                              s['value']!,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s['label']!,
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            const SizedBox(height: 28),

            // Archetypes
            const Text('Archetypes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                _archetypeChip(Icons.brush, userState.archetypes.isNotEmpty ? userState.archetypes.first : 'Creator', AppColors.questBlue),
                const SizedBox(width: 10),
                _archetypeChip(Icons.link, userState.archetypes.length > 1 ? userState.archetypes[1] : 'Connector', AppColors.auroraPurple),
              ],
            ),

            const SizedBox(height: 28),

            // Achievements & Badges
            const Text('Achievements & Badges', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _badge(Icons.rocket_launch, 'Early Adopter', AppColors.auroraPurple, true),
                _badge(Icons.local_fire_department, '${userState.streak}-Day Streak', Colors.orange, true),
                _badge(Icons.people, 'First Connection', AppColors.emerald, userState.joinedCommunityIds.isNotEmpty),
                _badge(Icons.emoji_events, 'Event Master', AppColors.gold, userState.rsvpdEventIds.isNotEmpty),
              ],
            ),

            const SizedBox(height: 32),

            // Admin & Hosting
            const Text('Admin & Hosting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/organization');
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: AppColors.emerald, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Organization Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Manage communities, attendees, and analytics', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _archetypeChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String label, Color color, bool unlocked) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: unlocked ? color.withValues(alpha: 0.4) : AppColors.border),
      ),
      child: Column(
        children: [
          Icon(unlocked ? icon : Icons.lock_outline, color: unlocked ? color : AppColors.textMuted, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: unlocked ? AppColors.textSecondary : AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

