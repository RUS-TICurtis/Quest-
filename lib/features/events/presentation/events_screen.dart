import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/quest_button.dart';
import '../../profile/data/user_provider.dart';
import '../data/events_provider.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _filters = ['All', 'Today', 'Tomorrow', 'This Weekend', 'Virtual'];

  @override
  Widget build(BuildContext context) {
    final eventsState = (ref.watch(eventsProvider).value ?? EventsState.initial());
    final userState = (ref.watch(userProvider).value ?? UserState.initial());
    final filteredEvents = eventsState.filteredEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.radar, color: AppColors.emerald),
            tooltip: 'Participation Radar',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/radar');
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: AppColors.crimson),
            tooltip: 'Live Stage Room',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/stage/stage_1');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Host Event',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHostEventSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final filter = _filters[i];
                final selected = eventsState.selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(eventsProvider.notifier).setFilter(filter);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.questBlue : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.questBlue : AppColors.border),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: filteredEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.event_busy, color: AppColors.textMuted, size: 48),
                      ),
                      const SizedBox(height: 24),
                        const Text('No events found', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        const Text('Try adjusting your filters or check back later.', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      const Text(
                        'Trending Near You',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 12),

                      // Featured Event (Large Card)
                      _featuredEventCard(filteredEvents.first, userState.rsvpdEventIds.contains(filteredEvents.first.id)),

                      if (filteredEvents.length > 1) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Upcoming',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 12),

                        // Standard Event List
                        ...filteredEvents.skip(1).map(
                              (e) => _eventListTile(e, userState.rsvpdEventIds.contains(e.id)),
                            ),
                      ],

                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _featuredEventCard(Event event, bool isRsvpd) {
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          image: DecorationImage(
            image: NetworkImage(event.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.darken),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: event.accentColor, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      event.date.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                  if (isRsvpd)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.emerald, borderRadius: BorderRadius.circular(6)),
                      child: const Text('RSVP\'d âœ“', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${event.location} â€¢ ${event.attendeesCount + (isRsvpd ? 1 : 0)} attending',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventListTile(Event event, bool isRsvpd) {
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Calendar icon block
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: event.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    (event.date.split(' ').first.length >= 3 ? event.date.split(' ').first.substring(0, 3) : event.date.split(' ').first).toUpperCase(),
                    style: TextStyle(color: event.accentColor, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  const Icon(Icons.event, color: Colors.white, size: 24),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.date} â€¢ ${event.time}',
                    style: const TextStyle(color: AppColors.questBlue, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event.location} â€¢ ${event.attendeesCount + (isRsvpd ? 1 : 0)} going',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isRsvpd)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.emerald, size: 16),
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  void _showHostEventSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '7:00 PM');
    String category = 'Networking';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Host an Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Gather members around a meetup, session, or talk.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Event Title...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Location or Virtual Link...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Time (e.g. 6:30 PM)...'),
            ),
            const SizedBox(height: 24),
            QuestButton(
              label: 'Publish Event',
              isFullWidth: true,
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  final newId = '${DateTime.now().millisecondsSinceEpoch}';
                  final newEvent = Event(
                    id: newId,
                    communityId: '1',
                    title: titleCtrl.text.trim(),
                    host: 'Community Host',
                    date: 'Tomorrow',
                    time: timeCtrl.text.trim(),
                    location: locCtrl.text.trim().isNotEmpty ? locCtrl.text.trim() : 'Downtown Hub',
                    attendeesCount: 1,
                    imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80',
                    category: category,
                    accentColor: AppColors.questBlue,
                    description: 'An interactive gathering organized by Quest members.',
                  );
                  ref.read(eventsProvider.notifier).addEvent(newEvent);
                  ref.read(userProvider.notifier).toggleRsvpEvent(newId);
                  Navigator.pop(sheetContext);
                  context.push('/events/$newId');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


