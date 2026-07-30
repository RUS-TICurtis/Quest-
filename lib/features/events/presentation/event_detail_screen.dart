import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

import 'events_screen.dart';

class EventDetailScreen extends StatelessWidget {
  final EventModel event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(event.imageUrl, fit: BoxFit.cover),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.8),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Host
                  Text(event.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: event.accentColor,
                        child: const Icon(Icons.group, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Text('Hosted by ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(event.host, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date & Location Cards
                  Row(
                    children: [
                      Expanded(child: _infoCard(Icons.calendar_today, event.date, event.time)),
                      const SizedBox(width: 12),
                      Expanded(child: _infoCard(Icons.location_on, 'Location', event.location)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // RSVP Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: event.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: event.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${event.attendeesCount} Attending', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('including 3 connections', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: event.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {},
                          child: const Text('RSVP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // About Section
                  const Text('About this Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 12),
                  const Text(
                    'Join us for an evening of networking, learning, and collaboration. We\'ll have guest speakers, interactive workshops, and plenty of time to connect with others in the community. Food and drinks will be provided.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                  ),

                  const SizedBox(height: 32),
                  
                  // Map placeholder
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, color: AppColors.textMuted, size: 32),
                          SizedBox(height: 8),
                          Text('Map View (Coming Soon)', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.questBlue, size: 20),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
