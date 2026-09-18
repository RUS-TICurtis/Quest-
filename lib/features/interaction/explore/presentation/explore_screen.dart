import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/explore/presentation/widgets/discover_components.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heroItems = [
      HeroItem(
        title: 'Global Game Jam 2026',
        subtitle: 'Join thousands of developers in a 48-hour coding sprint.',
        imageUrl: 'https://images.unsplash.com/photo-1552820728-8b83bb6b773f?auto=format&fit=crop&w=800&q=80',
        tag: 'Event',
        tagColor: context.colors.amber,
        route: '/events/1',
      ),
      HeroItem(
        title: 'Design Systems',
        subtitle: 'A community for UI/UX designers building scalable systems.',
        imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?auto=format&fit=crop&w=800&q=80',
        tag: 'Community',
        tagColor: context.colors.auroraPurple,
        route: '/communities/1',
      ),
      HeroItem(
        title: 'First Steps',
        subtitle: 'Complete your profile and join your first community.',
        imageUrl: 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=800&q=80',
        tag: 'Quest',
        tagColor: context.colors.emerald,
        route: '/quests/1',
      ),
    ];

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: context.colors.background,
            title: Text(
              'Explore',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: context.colors.textPrimary),
                onPressed: () => context.push('/explore/search'),
              ),
            ],
            floating: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Hero Slideshow Section
                DiscoverHeroSlideshow(items: heroItems),
                
                const SizedBox(height: 32),

                // Quick Actions (Horizontal Chips)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildQuickAction(context, 'Leaderboard', Icons.leaderboard, '/leaderboard'),
                      _buildQuickAction(context, 'Radar', Icons.radar, '/radar'),
                      _buildQuickAction(context, 'Stage', Icons.mic, '/stage/1'),
                      _buildQuickAction(context, 'Organization', Icons.business, '/organization'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Featured Communities Section
                _buildSectionHeader(
                  context,
                  title: 'Featured Communities',
                  onSeeAll: () => context.push('/communities'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      DiscoverHorizontalCard(
                        title: 'Flutter Builders',
                        subtitle: 'Technology',
                        imageUrl: 'https://images.unsplash.com/photo-1617042375876-a13e36732a30?auto=format&fit=crop&w=400&q=80',
                        onTap: () => context.push('/communities/1'),
                      ),
                      DiscoverHorizontalCard(
                        title: 'Startup Founders',
                        subtitle: 'Business',
                        imageUrl: 'https://images.unsplash.com/photo-1556761175-5973dc0f32d7?auto=format&fit=crop&w=400&q=80',
                        onTap: () => context.push('/communities/2'),
                      ),
                      DiscoverHorizontalCard(
                        title: 'Design Systems',
                        subtitle: 'Design',
                        imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5?auto=format&fit=crop&w=400&q=80',
                        onTap: () => context.push('/communities/3'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Trending Events Section
                _buildSectionHeader(
                  context,
                  title: 'Trending Events',
                  onSeeAll: () => context.push('/events'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      DiscoverHorizontalCard(
                        title: 'Tech Meetup 2026',
                        subtitle: 'San Francisco',
                        imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?auto=format&fit=crop&w=400&q=80',
                        onTap: () => context.push('/events/1'),
                      ),
                      DiscoverHorizontalCard(
                        title: 'Hackathon Finals',
                        subtitle: 'New York',
                        imageUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=400&q=80',
                        onTap: () => context.push('/events/2'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {required String title, required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(color: context.colors.questBlue),
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
}
