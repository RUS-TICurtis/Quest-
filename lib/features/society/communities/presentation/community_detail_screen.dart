import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/society/events/data/events_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/features/society/communities/data/community_posts_provider.dart';
import 'package:quest/features/society/communities/presentation/widgets/community_post_card.dart';

class CommunityDetailScreen extends ConsumerWidget {
  final String communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesState = ref.watch(communitiesProvider).value;
    final community = communitiesState?.communities
        .where((c) => c.id == communityId)
        .firstOrNull;
    final userState = (ref.watch(userProvider).value ?? UserState.initial());
    final eventsState =
        (ref.watch(eventsProvider).value ?? EventsState.initial());

    if (community == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Community')),
        body: Center(
          child: Text(
            'Community not found',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final isJoined = userState.joinedCommunityIds.contains(community.id);
    final communityEvents = eventsState.events
        .where((e) => e.communityId == community.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/communities');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      community.accentColor.withValues(alpha: 0.35),
                      AppColors.surface,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 48),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: community.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: community.accentColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          community.icon,
                          color: community.accentColor,
                          size: 38,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        community.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats + join button
                  Row(
                    children: [
                      _statPill(
                        Icons.people_outline,
                        '${community.memberCount + (isJoined ? 1 : 0)} members',
                        AppColors.textMuted,
                      ),
                      SizedBox(width: 10),
                      _statPill(
                        Icons.category_outlined,
                        community.category,
                        AppColors.textMuted,
                      ),
                      Spacer(),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 250),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isJoined
                                ? AppColors.card
                                : community.accentColor,
                            foregroundColor: isJoined
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            side: isJoined
                                ? BorderSide(color: AppColors.border)
                                : BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(userProvider.notifier)
                                .toggleJoinCommunity(community.id);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surface,
                                content: Text(
                                  isJoined
                                      ? 'Left ${community.name}'
                                      : 'Joined ${community.name}! +25 XP',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isJoined ? 'Joined âœ“' : 'Join Community',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),
                  Divider(color: AppColors.border),
                  SizedBox(height: 20),

                  // About
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    community.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 24),

                  // Location & Tags
                  Text(
                    'Focus & Tags',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: community.tags.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 28),

                  // Upcoming events in this community
                  Text(
                    'Upcoming Events',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  if (communityEvents.isEmpty)
                    _placeholderEventTile(context, community)
                  else
                    ...communityEvents.map(
                      (e) => _eventTile(
                        context,
                        ref,
                        e,
                        userState.rsvpdEventIds.contains(e.id),
                      ),
                    ),

                  SizedBox(height: 24),

                  // Members
                  Text(
                    'Active Members',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  _membersRow(community.memberCount),

                  SizedBox(height: 32),

                  // Discussion Board
                  Text(
                    'Discussion Board',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  ref.watch(communityPostsProvider(community.id)).when(
                        data: (posts) {
                          if (posts.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'No posts yet. Be the first to start a discussion!',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            );
                          }
                          return Column(
                            children: posts.map((post) => CommunityPostCard(post: post, community: community)).toList(),
                          );
                        },
                        loading: () => Center(
                          child: CircularProgressIndicator(color: AppColors.questBlue),
                        ),
                        error: (error, stack) => Center(
                          child: Text('Error loading posts', style: TextStyle(color: AppColors.crimson)),
                        ),
                      ),

                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Action bar at bottom
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.chat_bubble_outline, size: 18),
                label: Text('Community Chat'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/messages/1');
                },
              ),
            ),
            SizedBox(width: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.share_outlined, size: 18),
              label: Text('Share'),
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      'Community invite link copied for ${community.name}!',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventTile(
    BuildContext context,
    WidgetRef ref,
    Event event,
    bool isRsvpd,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/events/${event.id}');
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: event.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.event_outlined,
                color: event.accentColor,
                size: 22,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${event.date} â€¢ ${event.time}',
                    style: TextStyle(color: event.accentColor, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${event.attendeesCount + (isRsvpd ? 1 : 0)} going',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRsvpd
                        ? AppColors.surface
                        : event.accentColor,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: Size.zero,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(userProvider.notifier).toggleRsvpEvent(event.id);
                  },
                  child: Text(isRsvpd ? 'RSVP\'d âœ“' : 'RSVP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderEventTile(BuildContext context, Community community) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: community.accentColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No upcoming events scheduled yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _membersRow(int count) {
    final colors = [
      AppColors.questBlue,
      AppColors.emerald,
      AppColors.auroraPurple,
      AppColors.amber,
    ];
    final initials = ['AL', 'MK', 'SR', 'JD'];
    return Row(
      children: [
        ...List.generate(
          4,
          (i) => Transform.translate(
            offset: Offset(i * -10.0, 0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colors[i % colors.length],
              child: Text(
                initials[i],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 4),
        Text(
          '+ $count members',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }
}
