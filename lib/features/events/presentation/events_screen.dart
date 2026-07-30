import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'event_detail_screen.dart';

class EventModel {
  final String id;
  final String title;
  final String host;
  final String date;
  final String time;
  final String location;
  final int attendeesCount;
  final String imageUrl;
  final String category;
  final Color accentColor;

  const EventModel({
    required this.id,
    required this.title,
    required this.host,
    required this.date,
    required this.time,
    required this.location,
    required this.attendeesCount,
    required this.imageUrl,
    required this.category,
    required this.accentColor,
  });
}

final _mockEvents = [
  const EventModel(
    id: '1',
    title: 'Tech Startup Mixer',
    host: 'Startup Founders',
    date: 'Tonight',
    time: '7:00 PM',
    location: 'Downtown Innovation Hub',
    attendeesCount: 42,
    imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&q=80',
    category: 'Networking',
    accentColor: AppColors.emerald,
  ),
  const EventModel(
    id: '2',
    title: 'Flutter Architecture Workshop',
    host: 'Flutter Builders',
    date: 'Tomorrow',
    time: '6:30 PM',
    location: 'Tech Campus, Room 4B',
    attendeesCount: 128,
    imageUrl: 'https://images.unsplash.com/photo-1555952494-efd681c7e3f9?w=800&q=80',
    category: 'Workshop',
    accentColor: AppColors.questBlue,
  ),
  const EventModel(
    id: '3',
    title: 'City Photo Walk: Golden Hour',
    host: 'City Photographers',
    date: 'Saturday',
    time: '5:00 PM',
    location: 'Central Park South Entrance',
    attendeesCount: 15,
    imageUrl: 'https://images.unsplash.com/photo-1493606278519-11aa9f86e40a?w=800&q=80',
    category: 'Meetup',
    accentColor: AppColors.crimson,
  ),
  const EventModel(
    id: '4',
    title: 'Design Systems Round Table',
    host: 'Design Systems',
    date: 'Next Tuesday',
    time: '12:00 PM',
    location: 'Virtual (Zoom)',
    attendeesCount: 56,
    imageUrl: 'https://images.unsplash.com/photo-1542744173-8e7e53415bb0?w=800&q=80',
    category: 'Discussion',
    accentColor: AppColors.auroraPurple,
  ),
];

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _filters = ['All', 'Today', 'Tomorrow', 'This Weekend', 'Virtual'];
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Host Event',
            onPressed: () {},
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
                final selected = _selectedFilter == filter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.questBlue : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.questBlue : AppColors.border),
                    ),
                    child: Text(filter, style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                const Text('Trending Near You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 12),
                
                // Featured Event (Large Card)
                if (_mockEvents.isNotEmpty)
                  _featuredEventCard(_mockEvents.first),
                  
                const SizedBox(height: 24),
                const Text('Upcoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 12),
                
                // Standard Event List
                ..._mockEvents.skip(1).map((e) => _eventListTile(e)),
                
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredEventCard(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: event.accentColor, borderRadius: BorderRadius.circular(6)),
                child: Text(event.date.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 8),
              Text(event.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(event.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventListTile(EventModel event) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
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
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: event.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(event.date.split(' ').first.substring(0, 3).toUpperCase(), style: TextStyle(color: event.accentColor, fontSize: 10, fontWeight: FontWeight.w800)),
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
                  Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('${event.date} • ${event.time}', style: const TextStyle(color: AppColors.questBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(event.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
