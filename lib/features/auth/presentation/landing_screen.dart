import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/quest_button.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Ambient glow backgrounds
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            left: -100,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                color: AppColors.questBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            right: -80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: AppColors.auroraPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.questBlue,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: AppColors.questBlue.withValues(alpha: 0.4), blurRadius: 12)],
                        ),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Quest',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Headline
                  const Text(
                    'The Social\nOperating System\nfor Real-World\nConnection.',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -1.5,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Build communities. Discover events.\nLevel up your life.',
                    style: TextStyle(fontSize: 16, color: AppColors.textSecondary, height: 1.6),
                  ),

                  const Spacer(),

                  // Action Buttons
                  QuestButton(
                    label: 'Begin Your Quest',
                    isFullWidth: true,
                    icon: Icons.rocket_launch_outlined,
                    onPressed: () => Navigator.of(context).pushNamed('/onboarding'),
                  ),
                  const SizedBox(height: 12),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),

                  const SizedBox(height: 12),
                  QuestButton(
                    label: 'Continue with Google',
                    isFullWidth: true,
                    variant: QuestButtonVariant.secondary,
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: () {}, // Hook up Supabase Google Auth later
                  ),

                  const SizedBox(height: 24),

                  // Feature rows
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _featureChip(Icons.people, 'Communities'),
                      _featureChip(Icons.emoji_events, 'Reputation'),
                      _featureChip(Icons.auto_awesome, 'AI Coach'),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureChip(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.questBlue, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
