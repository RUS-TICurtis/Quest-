import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communitiesStateAsync = ref.watch(communitiesProvider);
    final communitiesState = communitiesStateAsync.value;

    if (communitiesState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.questBlue),
        ),
      );
    }
    final userState = (ref.watch(userProvider).value ?? UserState.initial());
    final allCommunities = communitiesState.filteredCommunities;
    final joined = allCommunities.where((c) => userState.joinedCommunityIds.contains(c.id)).toList();
    final discover = allCommunities.where((c) => !userState.joinedCommunityIds.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.questBlue,
        child: Icon(Icons.add, color: context.colors.textPrimary),
        onPressed: () {
          HapticFeedback.lightImpact();
          // _showCreateSheet(context);
        },
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: context.colors.background,
              title: Text(
                'Communities',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search, color: context.colors.textPrimary),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/explore/search');
                  },
                ),
              ],
              floating: true,
              pinned: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: context.colors.questBlue,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.questBlue.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: context.colors.textMuted,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: '🚀 Trending'),
                        Tab(text: '🎯 Joined'),
                        Tab(text: '🌎 All'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCommunityGrid(discover),
            _buildCommunityGrid(joined),
            _buildCommunityGrid(allCommunities),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityGrid(List<Community> communities) {
    if (communities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, color: context.colors.textMuted, size: 48),
            const SizedBox(height: 16),
            Text(
              'No communities found',
              style: TextStyle(color: context.colors.textMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final c = communities[index];
        return _buildCommunityCard(c);
      },
    );
  }

  Widget _buildCommunityCard(Community community) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/communities/${community.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Banner background
            Positioned.fill(
              child: community.bannerUrl != null
                  ? Image.network(
                      community.bannerUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, error, stackTrace) => Container(color: community.accentColor),
                    )
                  : Container(
                      color: community.accentColor,
                      child: Center(
                        child: Icon(
                          community.icon,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.black.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Content
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    community.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, color: Colors.white.withValues(alpha: 0.7), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${community.memberCount} members',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
