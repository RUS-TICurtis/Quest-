import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/events/data/events_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/core/video/presentation/video_feed.dart';
import 'package:quest/core/video/feed_video_pool.dart';

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
      backgroundColor: Colors.black, // Full dark mode for video feed
      extendBodyBehindAppBar: true, // Make app bar transparent over video
      appBar: AppBar(
        title: Text('Events', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.radar, color: context.colors.emerald),
            tooltip: 'Participation Radar',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/radar');
            },
          ),
          IconButton(
            icon: Icon(Icons.mic, color: context.colors.crimson),
            tooltip: 'Live Stage Room',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/stage/stage_1');
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            tooltip: 'Host Event',
            onPressed: () {
              HapticFeedback.lightImpact();
              _showHostEventSheet(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (filteredEvents.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    color: Colors.white54,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No events found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters or check back later.',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            VideoFeed<Event>(
              poolProvider: eventsVideoPoolProvider,
              items: filteredEvents,
              scrollDirection: Axis.vertical,
              urlBuilder: (event) {
                if (event.muxPlaybackId != null && event.muxPlaybackId!.isNotEmpty) {
                  return 'https://stream.mux.com/${event.muxPlaybackId!}.m3u8';
                }
                return event.videoUrl;
              },
              fallbackBuilder: (context, event, index) {
                // Fallback Image
                return Container(
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    image: DecorationImage(
                      image: NetworkImage(event.imageUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.5), // darken the image
                        BlendMode.darken,
                      ),
                    ),
                  ),
                );
              },
              overlayBuilder: (context, event, index) {
                final isRsvpd = userState.rsvpdEventIds.contains(event.id);
                return _buildEventOverlay(context, event, isRsvpd);
              },
            ),

          // Filters Overlay at the top (below AppBar)
          Positioned(
            top: MediaQuery.of(context).padding.top + 56, // below AppBar
            left: 0,
            right: 0,
            child: SizedBox(
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
                      HapticFeedback.selectionClick();
                      ref.read(eventsProvider.notifier).setFilter(filter);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? eventAccentOrPrimary(filteredEvents, context) : Colors.black45,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? eventAccentOrPrimary(filteredEvents, context) : Colors.white24,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color eventAccentOrPrimary(List<Event> events, BuildContext context) {
    if (events.isNotEmpty) {
      return events.first.accentColor;
    }
    return context.colors.questBlue;
  }

  Widget _buildEventOverlay(BuildContext context, Event event, bool isRsvpd) {
    return Positioned(
      bottom: 40,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: event.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  event.date.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isRsvpd)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.emerald,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RSVP\'d ✓',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            event.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              shadows: [
                Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 2)),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white70, size: 16),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${event.location} • ${event.attendeesCount + (isRsvpd ? 1 : 0)} attending',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(eventsProvider.notifier).toggleRsvp(event.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRsvpd ? Colors.white24 : event.accentColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isRsvpd ? 'Cancel RSVP' : 'RSVP Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.info_outline, color: Colors.white),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push('/events/${event.id}');
                  },
                ),
              ),
            ],
          )
        ],
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
