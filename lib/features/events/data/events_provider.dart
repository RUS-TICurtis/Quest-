import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/data/user_provider.dart';
import 'events_repository.dart';

class Event {
  final String id;
  final String communityId;
  final String title;
  final String host;
  final String date;
  final String time;
  final String location;
  final int attendeesCount;
  final String imageUrl;
  final String category;
  final Color accentColor;
  final String description;
  final int xpReward;
  final bool isRsvpd;

  const Event({
    required this.id,
    required this.communityId,
    required this.title,
    this.host = 'Quest Guild',
    required this.date,
    required this.time,
    required this.location,
    this.attendeesCount = 0,
    this.imageUrl = 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
    required this.category,
    this.accentColor = AppColors.questBlue,
    required this.description,
    this.xpReward = 150,
    this.isRsvpd = false,
  });

  Event copyWith({
    String? id,
    String? communityId,
    String? title,
    String? host,
    String? date,
    String? time,
    String? location,
    int? attendeesCount,
    String? imageUrl,
    String? category,
    Color? accentColor,
    String? description,
    int? xpReward,
    bool? isRsvpd,
  }) {
    return Event(
      id: id ?? this.id,
      communityId: communityId ?? this.communityId,
      title: title ?? this.title,
      host: host ?? this.host,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      accentColor: accentColor ?? this.accentColor,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      isRsvpd: isRsvpd ?? this.isRsvpd,
    );
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      communityId: json['communityId'] as String,
      title: json['title'] as String,
      host: json['host'] as String? ?? 'Quest Guild',
      date: json['date'] as String,
      time: json['time'] as String,
      location: json['location'] as String,
      attendeesCount: json['attendeesCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      category: json['category'] as String,
      accentColor: Color(json['accentColor'] as int? ?? AppColors.questBlue.toARGB32()),
      description: json['description'] as String,
      xpReward: json['xpReward'] as int? ?? 150,
      isRsvpd: json['isRsvpd'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'communityId': communityId,
      'title': title,
      'host': host,
      'date': date,
      'time': time,
      'location': location,
      'attendeesCount': attendeesCount,
      'imageUrl': imageUrl,
      'category': category,
      'accentColor': accentColor.toARGB32(),
      'description': description,
      'xpReward': xpReward,
      'isRsvpd': isRsvpd,
    };
  }
}

class EventsState {
  final List<Event> events;
  final String selectedFilter;

  const EventsState({
    required this.events,
    this.selectedFilter = 'All',
  });

  factory EventsState.initial() {
    return const EventsState(events: []);
  }

  List<Event> get filteredEvents {
    if (selectedFilter == 'All') return events;
    return events.where((e) => e.category.toLowerCase() == selectedFilter.toLowerCase()).toList();
  }

  EventsState copyWith({
    List<Event>? events,
    String? selectedFilter,
  }) {
    return EventsState(
      events: events ?? this.events,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class EventsNotifier extends AsyncNotifier<EventsState> {
  late EventsRepository _repository;

  @override
  Future<EventsState> build() async {
    _repository = ref.watch(eventsRepositoryProvider);
    final events = await _repository.getEvents();

    // Only watch rsvpdEventIds to avoid rebuilding on unrelated user state changes
    // (name, level, streak, etc.) — .select() narrows the dependency.
    final rsvpdIds = ref.watch(
      userProvider.select((async) => async.value?.rsvpdEventIds ?? <String>[]),
    );

    // Update the isRsvpd field on events based on user state
    final updatedEvents = events.map((e) => e.copyWith(isRsvpd: rsvpdIds.contains(e.id))).toList();

    return EventsState(events: updatedEvents);
  }

  void setFilter(String filter) {
    final currentState = state.value;
    if (currentState == null) return;
    state = AsyncData(currentState.copyWith(selectedFilter: filter));
  }

  Future<void> toggleRsvp(String eventId) async {
    // We now just delegate to the userProvider. 
    // Since we watch userProvider in build(), this provider will automatically rebuild
    // with the updated RSVP statuses when the user state changes.
    // However, we also need to update the attendee count on the backend.
    
    final currentState = state.value;
    if (currentState == null) return;
    
    final eventIndex = currentState.events.indexWhere((e) => e.id == eventId);
    if (eventIndex == -1) return;
    
    final event = currentState.events[eventIndex];
    final isCurrentlyRsvpd = event.isRsvpd;
    
    final updatedEvent = event.copyWith(
      attendeesCount: isCurrentlyRsvpd ? event.attendeesCount - 1 : event.attendeesCount + 1,
      // isRsvpd is derived from user state, but we can optimistically update it for immediate UI feedback
      isRsvpd: !isCurrentlyRsvpd,
    );
    
    final updatedEvents = List<Event>.from(currentState.events);
    updatedEvents[eventIndex] = updatedEvent;
    
    // Optimistic UI update
    state = AsyncData(currentState.copyWith(events: updatedEvents));
    
    // Fire off backend update
    await _repository.updateEvent(updatedEvent);
    
    // Toggle RSVP on the user (which adds/removes XP and saves to user repository)
    await ref.read(userProvider.notifier).toggleRsvpEvent(eventId);
  }

  Future<void> addEvent(Event newEvent) async {
    final currentState = state.value;
    if (currentState == null) return;
    
    // Normally you'd send to backend here, but for this mock:
    state = AsyncData(currentState.copyWith(
      events: [newEvent, ...currentState.events],
    ));
  }

  Event? getEventById(String eventId) {
    final currentState = state.value;
    if (currentState == null) return null;
    
    try {
      return currentState.events.firstWhere((e) => e.id == eventId);
    } catch (_) {
      return currentState.events.isNotEmpty ? currentState.events.first : null;
    }
  }
}

final eventsProvider = AsyncNotifierProvider<EventsNotifier, EventsState>(() {
  return EventsNotifier();
});
