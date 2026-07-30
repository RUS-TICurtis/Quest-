import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = [
      {'label': 'Level', 'value': '4'},
      {'label': 'XP', 'value': '840'},
      {'label': 'Streak', 'value': '12'},
      {'label': 'Badges', 'value': '8'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () {}),
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
                        child: const Text('AL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      ),
                      Positioned(
                        bottom: 2, right: 2,
                        child: Container(
                          width: 20, height: 20,
                          decoration: BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2.5)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Alex L.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.gold.withValues(alpha: 0.3))),
                    child: const Text('Lvl 4 Creator & Connector', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(
                children: stats.map((s) => Expanded(
                  child: Column(
                    children: [
                      Text(s['value']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(s['label']!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // Archetypes
            const Text('Archetypes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            Row(
              children: [
                _archetypeChip(Icons.brush, 'Creator', AppColors.questBlue),
                const SizedBox(width: 10),
                _archetypeChip(Icons.link, 'Connector', AppColors.auroraPurple),
              ],
            ),

            const SizedBox(height: 28),

            // Achievements
            const Text('Achievements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: [
                _badge(Icons.rocket_launch, 'Early Adopter', AppColors.auroraPurple),
                _badge(Icons.local_fire_department, '7-Day Streak', Colors.orange),
                _badge(Icons.people, 'First Connection', AppColors.emerald),
                _badge(Icons.lock_outline, '???', AppColors.border),
              ],
            ),
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

  Widget _badge(IconData icon, String label, Color color) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
