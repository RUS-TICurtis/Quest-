import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/features/society/events/data/events_provider.dart';
import 'widgets/create_event_sheet.dart';
import 'widgets/post_announcement_sheet.dart';

class OrganizationDashboardScreen extends ConsumerWidget {
  const OrganizationDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communitiesStateAsync = ref.watch(communitiesProvider);
    final communitiesState = communitiesStateAsync.value;
    final eventsState =
        (ref.watch(eventsProvider).value ?? EventsState.initial());

    if (communitiesState == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.questBlue),
        ),
      );
    }

    final totalMembers = communitiesState.communities.fold<int>(
      0,
      (sum, c) => sum + c.memberCount,
    );
    final totalEvents = eventsState.events.length;
    final totalRsvps = eventsState.events.fold<int>(
      0,
      (sum, e) => sum + e.attendeesCount,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Host & Organization Portal'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Overview Header
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.questBlue.withValues(alpha: 0.8),
                  AppColors.auroraPurple.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Community Reach',
                  style: TextStyle(
                    color: AppColors.textPrimary70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '3,850 XP Generated',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statItem('Total Members', '$totalMembers'),
                    _statItem('Active Events', '$totalEvents'),
                    _statItem('Total RSVPs', '$totalRsvps'),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 32),
          Text(
            'Managed Communities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),

          ...communitiesState.communities
              .take(3)
              .map(
                (c) => Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/communities/${c.id}');
                    },
                    child: _manageCommunityCard(
                      title: c.name,
                      members: c.memberCount,
                      updates: c.id == '1' ? 2 : 0,
                      color: c.accentColor,
                    ),
                  ),
                ),
              ),

          SizedBox(height: 24),

          // Quick Actions
          Text(
            'Admin Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _actionCard(
                  icon: Icons.event,
                  title: 'Host Event',
                  color: AppColors.emerald,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    CreateEventSheet.show(context);
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _actionCard(
                  icon: Icons.campaign,
                  title: 'Announcement',
                  color: AppColors.crimson,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    PostAnnouncementSheet.show(context);
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.textPrimary70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _manageCommunityCard({
    required String title,
    required int members,
    required int updates,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.groups, color: color),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$members Members',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (updates > 0)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.crimson,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$updates Needs Review',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
