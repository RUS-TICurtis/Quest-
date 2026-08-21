import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/events/data/events_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsState =
        (ref.watch(eventsProvider).value ?? EventsState.initial());
    final cleanId = eventId.replaceAll(RegExp(r'^e'), '');
    final event = eventsState.events.cast<Event?>().firstWhere(
      (e) => e?.id == eventId || e?.id == cleanId || 'e${e?.id}' == eventId,
      orElse: () =>
          eventsState.events.isNotEmpty ? eventsState.events.first : null,
    );
    final userState = (ref.watch(userProvider).value ?? UserState.initial());

    if (event == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text('Event')),
        body: Center(
          child: Text(
            'Event not found',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    final isRsvpd = userState.rsvpdEventIds.contains(event.id);
    final attendeeCount = event.attendeesCount + (isRsvpd ? 1 : 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero image app bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                HapticFeedback.lightImpact();
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/events');
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.card,
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: AppColors.textMuted,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
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
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Host
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: event.accentColor,
                        child: Icon(
                          Icons.group,
                          size: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hosted by ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        event.host,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          event.category,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Date & Location Cards
                  Row(
                    children: [
                      Expanded(
                        child: _infoCard(
                          Icons.calendar_today,
                          event.date,
                          event.time,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.push('/radar');
                          },
                          child: _infoCard(
                            Icons.location_on,
                            'Location (Radar)',
                            event.location,
                            isTappable: true,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // RSVP Bar Card
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: event.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: event.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$attendeeCount Attending',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                isRsvpd
                                    ? 'You are attending! +30 XP gained'
                                    : 'Join fellow members in person',
                                style: TextStyle(
                                  color: isRsvpd
                                      ? AppColors.emerald
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isRsvpd
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRsvpd
                                ? AppColors.surface
                                : event.accentColor,
                            foregroundColor: AppColors.textPrimary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            side: isRsvpd
                                ? BorderSide(color: AppColors.border)
                                : BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (!isRsvpd) {
                              HapticFeedback.heavyImpact();
                              ref.read(userProvider.notifier).addXp(30);
                            } else {
                              HapticFeedback.mediumImpact();
                            }
                            ref
                                .read(userProvider.notifier)
                                .toggleRsvpEvent(event.id);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surface,
                                content: Text(
                                  isRsvpd
                                      ? 'RSVP Cancelled'
                                      : 'RSVP Confirmed! +30 XP Earned!',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isRsvpd ? 'RSVP\'d âœ“' : 'RSVP Now',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 28),

                  // About Section
                  Text(
                    'About this Event',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    event.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: 28),

                  // AI Guide Suggestion Box
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.skyBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.skyBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: AppColors.skyBlue,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Guide Recommendation',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Based on your interests, this is a prime event to meet future collaborators.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
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
                label: Text('Event Discussion'),
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
                _showShareModal(context, event);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showShareModal(BuildContext context, Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.qr_code_2,
                  color: AppColors.questBlue,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Invite fellow builders to this event',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.link, color: AppColors.gold),
              title: Text(
                'Copy Event Link',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                'https://quest.app/events/e1',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                HapticFeedback.lightImpact();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.card,
                    content: Text('Event link copied to clipboard!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.radar, color: AppColors.questBlue),
              title: Text(
                'Broadcast on Local Radar',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: Text(
                'Alert nearby members in your hub',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                HapticFeedback.lightImpact();
                Navigator.pop(ctx);
                context.push('/radar');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String title,
    String subtitle, {
    bool isTappable = false,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTappable
              ? AppColors.questBlue.withValues(alpha: 0.6)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isTappable ? AppColors.questBlue : AppColors.questBlue,
                size: 20,
              ),
              if (isTappable) ...[
                Spacer(),
                Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.questBlue,
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
