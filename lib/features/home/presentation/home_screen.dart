import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const xp = 840;
    const xpNeeded = 1000;
    const progress = xp / xpNeeded;

    final quests = [
      {'title': 'RSVP to a local event', 'xp': 50, 'done': true},
      {'title': 'Connect with a new person', 'xp': 100, 'done': false},
      {'title': 'Post to your community', 'xp': 75, 'done': false},
    ];

    final events = [
      {'title': 'Tech Startup Mixer', 'time': 'Tonight, 7:00 PM', 'location': 'Downtown Hub', 'attendees': 42},
      {'title': 'Weekend Hackathon', 'time': 'Saturday, 9:00 AM', 'location': 'Innovation Labs', 'attendees': 128},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.questBlue,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.questBlue,
                    child: const Text('AL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Good morning, Alex.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Ready to continue your journey?', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                        SizedBox(width: 4),
                        Text('12', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),

              const SizedBox(height: 20),

              // XP Bar card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lvl 4 Creator', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('$xp / $xpNeeded XP', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surface,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // AI Coach
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.auto_awesome, color: AppColors.skyBlue, size: 16),
                        SizedBox(width: 8),
                        Text('AI COACH SUGGESTION', style: TextStyle(color: AppColors.skyBlue, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Three people nearby share your interests.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('They are attending the Tech Startup Mixer tonight.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.skyBlue, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      onPressed: () {},
                      child: const Text('View Event', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Daily Quests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Quests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const Text('Resets in 8h', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 12),
              ...quests.map((q) => _questTile(q)),

              const SizedBox(height: 28),

              // Upcoming Events
              const Text('Upcoming Events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 12),
              ...events.map((e) => _eventTile(e)),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questTile(Map<String, dynamic> quest) {
    final isDone = quest['done'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, color: isDone ? AppColors.emerald : AppColors.border, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              quest['title'] as String,
              style: TextStyle(
                color: isDone ? AppColors.textMuted : Colors.white,
                decoration: isDone ? TextDecoration.lineThrough : null,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('+${quest['xp']} XP', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _eventTile(Map<String, dynamic> event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(event['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                child: Text('${event['attendees']} going', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(event['time'] as String, style: const TextStyle(color: AppColors.questBlue, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(event['location'] as String, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
