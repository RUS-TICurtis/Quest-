import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/quest_icons.dart';
import '../data/user_provider.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  final String memberId;

  const MemberProfileScreen({
    super.key,
    required this.memberId,
  });

  @override
  ConsumerState<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  bool _hasEndorsed = false;

  @override
  Widget build(BuildContext context) {
    // Mock profile data for member lookup
    final isAlex = widget.memberId == 'u_curr';
    final name = isAlex ? 'Alex L.' : 'Sarah Chen';
    final initials = isAlex ? 'AL' : 'SC';
    final role = isAlex ? 'Lead Product Engineer' : 'Founder & YC Alum';
    final bio = isAlex
        ? 'Passionate about mobile craft, real-time collaboration engines, and gamified systems.'
        : 'Building the future of decentralized collaboration. YC S22 alum, ex-Stripe engineer. Obsessed with participatory software.';
    final level = isAlex ? 4 : 9;
    final currentXp = isAlex ? 940 : 4200;
    final streak = isAlex ? 12 : 24;
    final archetypes = isAlex ? ['Builder', 'Connector'] : ['Strategist', 'Builder', 'Pioneer'];
    final badges = isAlex
        ? ['Early Adopter', '7-Day Streak', 'First Connection']
        : ['Top Strategist S2', '20-Day Streak', 'Guild Host', 'Hackathon Judge'];

    final archetypeScores = {
      'Strategist': 92,
      'Builder': 85,
      'Pioneer': 74,
      'Connector': 65,
      'Explorer': 58,
      'Scholar': 40,
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient Banner
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Back',
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.auroraPurple, AppColors.questBlue, AppColors.background],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar & Action Row
                  Transform.translate(
                    offset: const Offset(0, -40),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.background, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.questBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            context.push('/messages/t1');
                          },
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _hasEndorsed ? AppColors.gold : Colors.white,
                            side: BorderSide(color: _hasEndorsed ? AppColors.gold : AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          child: Icon(_hasEndorsed ? Icons.star : Icons.star_border, size: 18),
                          onPressed: () {
                            if (!_hasEndorsed) {
                              setState(() {
                                _hasEndorsed = true;
                              });
                              ref.read(userProvider.notifier).addXp(25);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: AppColors.card,
                                  content: Row(
                                    children: [
                                      Icon(Icons.workspace_premium, color: AppColors.gold),
                                      SizedBox(width: 10),
                                      Text('Endorsed archetype! +25 XP awarded.'),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Name, Bio & Level
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                'LVL $level',
                                style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(role, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: archetypes.map((arch) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.questBlue.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(QuestIcons.forArchetype(arch), size: 12, color: AppColors.questBlue),
                                  const SizedBox(width: 4),
                                  Text(arch, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Text(bio, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                        const SizedBox(height: 16),

                        // Stats Summary Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem('Total XP', '$currentXp', Icons.bolt, AppColors.gold),
                              Container(height: 24, width: 1, color: AppColors.border),
                              _buildStatItem('Streak', '$streak Days', Icons.local_fire_department, AppColors.crimson),
                              Container(height: 24, width: 1, color: AppColors.border),
                              _buildStatItem('Badges', '${badges.length}', Icons.military_tech, AppColors.emerald),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Archetype Radar Matrix Breakdown
                        const Text(
                          'ARCHETYPE MATRIX SCORE',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: archetypeScores.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Icon(QuestIcons.forArchetype(entry.key), size: 14, color: AppColors.questBlue),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: entry.value / 100.0,
                                          backgroundColor: AppColors.surface,
                                          valueColor: AlwaysStoppedAnimation(
                                            entry.value > 80 ? AppColors.gold : AppColors.questBlue,
                                          ),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${entry.value}%',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Badges Grid
                        const Text(
                          'UNLOCKED REPUTATION BADGES',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: badges.map((b) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium, color: AppColors.gold, size: 16),
                                  const SizedBox(width: 6),
                                  Text(b, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
      ],
    );
  }
}
