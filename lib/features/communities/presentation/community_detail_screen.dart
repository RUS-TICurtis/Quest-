import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/data/events_provider.dart';
import '../../profile/data/user_provider.dart';
import '../data/communities_provider.dart';

class CommunityDetailScreen extends ConsumerWidget {
  final String communityId;

  const CommunityDetailScreen({
    super.key,
    required this.communityId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesNotifier = ref.watch(communitiesProvider.notifier);
    final community = communitiesNotifier.getCommunityById(communityId);
    final userState = ref.watch(userProvider);
    final eventsState = ref.watch(eventsProvider);

    if (community == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Community')),
        body: const Center(
          child: Text('Community not found', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }

    final isJoined = userState.joinedCommunityIds.contains(community.id);
    final communityEvents = eventsState.events.where((e) => e.communityId == community.id).toList();

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
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
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
                      const SizedBox(height: 48),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: community.accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: community.accentColor.withValues(alpha: 0.5)),
                        ),
                        child: Icon(community.icon, color: community.accentColor, size: 38),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        community.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats + join button
                  Row(
                    children: [
                      _statPill(Icons.people_outline, '${community.memberCount + (isJoined ? 1 : 0)} members', AppColors.textMuted),
                      const SizedBox(width: 10),
                      _statPill(Icons.category_outlined, community.category, AppColors.textMuted),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isJoined ? AppColors.card : community.accentColor,
                            foregroundColor: isJoined ? AppColors.textSecondary : Colors.white,
                            side: isJoined ? const BorderSide(color: AppColors.border) : BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          onPressed: () {
                            ref.read(userProvider.notifier).toggleJoinCommunity(community.id);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surface,
                                content: Text(
                                  isJoined ? 'Left ${community.name}' : 'Joined ${community.name}! +25 XP',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isJoined ? 'Joined ✓' : 'Join Community',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 20),

                  // About
                  const Text('About', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    community.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                  ),

                  const SizedBox(height: 24),

                  // Location & Tags
                  const Text('Focus & Tags', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: community.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Upcoming events in this community
                  const Text('Upcoming Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  if (communityEvents.isEmpty)
                    _placeholderEventTile(context, community)
                  else
                    ...communityEvents.map((e) => _eventTile(context, ref, e, userState.rsvpdEventIds.contains(e.id))),

                  const SizedBox(height: 24),

                  // Members
                  const Text('Active Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 12),
                  _membersRow(community.memberCount),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),

      // Action bar at bottom
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Community Chat'),
                onPressed: () => context.push('/messages/1'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('Community invite link copied for ${community.name}!'),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _eventTile(BuildContext context, WidgetRef ref, Event event, bool isRsvpd) {
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
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
              child: Icon(Icons.event_outlined, color: event.accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${event.date} • ${event.time}', style: TextStyle(color: event.accentColor, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${event.attendeesCount + (isRsvpd ? 1 : 0)} going', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRsvpd ? AppColors.surface : event.accentColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    ref.read(userProvider.notifier).toggleRsvpEvent(event.id);
                  },
                  child: Text(isRsvpd ? 'RSVP\'d ✓' : 'RSVP'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: community.accentColor, size: 20),
          const SizedBox(width: 12),
          const Expanded(
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
    final colors = [AppColors.questBlue, AppColors.emerald, AppColors.auroraPurple, AppColors.amber];
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
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text('+ $count members', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}
