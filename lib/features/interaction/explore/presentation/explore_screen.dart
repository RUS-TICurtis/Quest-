import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Banner
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: context.colors.background,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Explore Quest',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.colors.questBlue,
                      context.colors.auroraPurple,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.explore,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions (Horizontal Chips)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildQuickAction(context, 'Leaderboard', Icons.leaderboard, '/leaderboard'),
                        _buildQuickAction(context, 'Radar', Icons.radar, '/radar'),
                        _buildQuickAction(context, 'Stage', Icons.mic, '/stage/1'),
                        _buildQuickAction(context, 'Organization', Icons.business, '/organization'),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // Featured Communities Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Featured Communities',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/communities'),
                          child: Text(
                            'See All',
                            style: TextStyle(color: context.colors.questBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildHorizontalCard(
                          context,
                          'Flutter Builders',
                          'Technology',
                          Icons.phone_android,
                          context.colors.questBlue,
                          '/communities/1',
                        ),
                        _buildHorizontalCard(
                          context,
                          'Startup Founders',
                          'Business',
                          Icons.rocket_launch,
                          context.colors.emerald,
                          '/communities/2',
                        ),
                        _buildHorizontalCard(
                          context,
                          'Design Systems',
                          'Design',
                          Icons.palette,
                          context.colors.auroraPurple,
                          '/communities/3',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),
                  
                  // Trending Events Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trending Events',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/events'),
                          child: Text(
                            'See All',
                            style: TextStyle(color: context.colors.questBlue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  SizedBox(
                    height: 160,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildHorizontalCard(
                          context,
                          'Tech Meetup 2026',
                          'Networking',
                          Icons.event,
                          context.colors.amber,
                          '/events/1',
                        ),
                        _buildHorizontalCard(
                          context,
                          'Hackathon Finals',
                          'Competition',
                          Icons.emoji_events,
                          context.colors.crimson,
                          '/events/2',
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, String label, IconData icon, String route) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: ActionChip(
        backgroundColor: context.colors.card,
        side: BorderSide(color: context.colors.border),
        avatar: Icon(icon, size: 16, color: context.colors.questBlue),
        label: Text(label, style: TextStyle(color: context.colors.textPrimary)),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push(route);
        },
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      child: Container(
        width: 140,
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
