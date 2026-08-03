import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/data/user_provider.dart';
import '../data/events_provider.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsState = ref.watch(eventsProvider);
    final cleanId = eventId.replaceAll(RegExp(r'^e'), '');
    final event = eventsState.events.cast<Event?>().firstWhere(
          (e) => e?.id == eventId || e?.id == cleanId || 'e${e?.id}' == eventId,
          orElse: () => eventsState.events.isNotEmpty ? eventsState.events.first : null,
        );
    final userState = ref.watch(userProvider);

    if (event == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Event')),
        body: const Center(
          child: Text('Event not found', style: TextStyle(color: AppColors.textMuted)),
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
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () {
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
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: AppColors.textMuted, size: 48),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Host
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: event.accentColor,
                        child: const Icon(Icons.group, size: 13, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text('Hosted by ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      Text(
                        event.host,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Date & Location Cards
                  Row(
                    children: [
                      Expanded(child: _infoCard(Icons.calendar_today, event.date, event.time)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/radar'),
                          child: _infoCard(Icons.location_on, 'Location (Radar)', event.location, isTappable: true),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // RSVP Bar Card
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
                              Text(
                                '$attendeeCount Attending',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isRsvpd ? 'You are attending! +30 XP gained' : 'Join fellow members in person',
                                style: TextStyle(
                                  color: isRsvpd ? AppColors.emerald : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isRsvpd ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRsvpd ? AppColors.surface : event.accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            side: isRsvpd ? const BorderSide(color: AppColors.border) : BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            ref.read(userProvider.notifier).toggleRsvpEvent(event.id);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surface,
                                content: Text(
                                  isRsvpd ? 'RSVP Cancelled' : 'RSVP Confirmed! +30 XP Earned!',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isRsvpd ? 'RSVP\'d ✓' : 'RSVP Now',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // About Section
                  const Text('About this Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.6),
                  ),

                  const SizedBox(height: 28),

                  // AI Guide Suggestion Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.skyBlue.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppColors.skyBlue, size: 20),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Guide Recommendation',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Based on your interests, this is a prime event to meet future collaborators.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          )
        ],
      ),
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
                label: const Text('Event Discussion'),
                onPressed: () => context.push('/messages/1'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share'),
              onPressed: () => _showShareModal(context, event),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2, color: AppColors.questBlue, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Invite fellow builders to this event', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.link, color: AppColors.gold),
              title: const Text('Copy Event Link', style: TextStyle(color: Colors.white)),
              subtitle: const Text('https://quest.app/events/e1', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.card,
                    content: Text('Event link copied to clipboard!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.radar, color: AppColors.questBlue),
              title: const Text('Broadcast on Local Radar', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Alert nearby members in your hub', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/radar');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String subtitle, {bool isTappable = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isTappable ? AppColors.questBlue.withValues(alpha: 0.6) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isTappable ? AppColors.questBlue : AppColors.questBlue, size: 20),
              if (isTappable) ...[
                const Spacer(),
                const Icon(Icons.open_in_new, size: 14, color: AppColors.questBlue),
              ]
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
