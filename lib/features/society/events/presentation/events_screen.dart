import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/events/data/events_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final _filters = ['All', 'Today', 'Tomorrow', 'This Weekend', 'Virtual'];

  @override
  Widget build(BuildContext context) {
    final eventsState =
        (ref.watch(eventsProvider).value ?? EventsState.initial());
    final userState = (ref.watch(userProvider).value ?? UserState.initial());
    final filteredEvents = eventsState.filteredEvents;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Events'),
        actions: [
          IconButton(
            icon: Icon(Icons.radar, color: context.colors.emerald),
            tooltip: 'Participation Radar',
            onPressed: () {
              HapticFeedback.lightImpact();
              HapticFeedback.lightImpact();
              context.push('/radar');
            },
          ),
          IconButton(
            icon: Icon(Icons.mic, color: context.colors.crimson),
            tooltip: 'Live Stage Room',
            onPressed: () {
              HapticFeedback.lightImpact();
              HapticFeedback.lightImpact();
              context.push('/stage/stage_1');
            },
          ),
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Host Event',
            onPressed: () {
              HapticFeedback.lightImpact();
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => SizedBox(width: 8),
              itemBuilder: (_, i) {
                final filter = _filters[i];
                final selected = eventsState.selectedFilter == filter;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    HapticFeedback.selectionClick();
                    ref.read(eventsProvider.notifier).setFilter(filter);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? context.colors.questBlue : context.colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? context.colors.questBlue
                            : context.colors.border,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: selected
                            ? context.colors.textPrimary
                            : context.colors.textMuted,
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
                        Icon(
                          Icons.event_busy,
                          color: context.colors.textMuted,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No events found',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or check back later.',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    children: [
                      Text(
                        'Trending Near You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 12),

                      // Featured Event (Large Card)
                      _featuredEventCard(
                        filteredEvents.first,
                        userState.rsvpdEventIds.contains(
                          filteredEvents.first.id,
                        ),
                      ),

                      if (filteredEvents.length > 1) ...[
                        SizedBox(height: 24),
                        Text(
                          'Upcoming',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 12),

                        // Standard Event List
                        ...filteredEvents
                            .skip(1)
                            .map(
                              (e) => _eventListTile(
                                e,
                                userState.rsvpdEventIds.contains(e.id),
                              ),
                            ),
                      ],

                      SizedBox(height: 80),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _featuredEventCard(Event event, bool isRsvpd) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/events/${event.id}');
      },
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border),
          image: DecorationImage(
            image: NetworkImage(event.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              context.colors.background.withValues(alpha: 0.6),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: event.accentColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.date.toUpperCase(),
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (isRsvpd)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.emerald,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'RSVP\'d âœ“',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                event.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: context.colors.textMuted,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${event.location} â€¢ ${event.attendeesCount + (isRsvpd ? 1 : 0)} attending',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                      ),
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
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/events/${event.id}');
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
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
                    (event.date.split(' ').first.length >= 3
                            ? event.date.split(' ').first.substring(0, 3)
                            : event.date.split(' ').first)
                        .toUpperCase(),
                    style: TextStyle(
                      color: event.accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Icon(
                    Icons.event,
                    color: context.colors.textPrimary,
                    size: 24,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${event.date} â€¢ ${event.time}',
                    style: TextStyle(
                      color: context.colors.questBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${event.location} â€¢ ${event.attendeesCount + (isRsvpd ? 1 : 0)} going',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isRsvpd)
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.colors.emerald.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: context.colors.emerald,
                  size: 16,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: context.colors.textMuted,
                size: 20,
              ),
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
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host an Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Gather members around a meetup, session, or talk.',
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 20),
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(hintText: 'Event Title...'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: locCtrl,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Location or Virtual Link...',
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: timeCtrl,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Time (e.g. 6:30 PM)...',
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (titleCtrl.text.trim().isNotEmpty) {
                    final newId = '${DateTime.now().millisecondsSinceEpoch}';
                    final newEvent = Event(
                      id: newId,
                      communityId: '1',
                      title: titleCtrl.text.trim(),
                      host: 'Community Host',
                      date: 'Tomorrow',
                      time: timeCtrl.text.trim(),
                      location: locCtrl.text.trim().isNotEmpty
                          ? locCtrl.text.trim()
                          : 'Downtown Hub',
                      attendeesCount: 1,
                      imageUrl:
                          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80',
                      category: category,
                      accentColor: context.colors.questBlue,
                      description:
                          'An interactive gathering organized by Quest members.',
                    );
                    ref.read(eventsProvider.notifier).addEvent(newEvent);
                    ref.read(userProvider.notifier).toggleRsvpEvent(newId);
                    Navigator.pop(sheetContext);
                    context.push('/events/$newId');
                  }
                },
                child: Text('Publish Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
