import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

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
}

class EventsState {
  final List<Event> events;
  final Set<String> rsvpdEventIds;
  final String selectedFilter;

  const EventsState({
    required this.events,
    this.rsvpdEventIds = const {'1'},
    this.selectedFilter = 'All',
  });

  List<Event> get filteredEvents {
    if (selectedFilter == 'All') return events;
    return events.where((e) => e.category.toLowerCase() == selectedFilter.toLowerCase()).toList();
  }

  EventsState copyWith({
    List<Event>? events,
    Set<String>? rsvpdEventIds,
    String? selectedFilter,
  }) {
    return EventsState(
      events: events ?? this.events,
      rsvpdEventIds: rsvpdEventIds ?? this.rsvpdEventIds,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class EventsNotifier extends Notifier<EventsState> {
  @override
  EventsState build() {
    return const EventsState(
      rsvpdEventIds: {'1'},
      events: [
        Event(
          id: '1',
          communityId: '1',
          title: 'Founder Fireside: Zero to Scale',
          host: 'Sarah Chen (Y Combinator)',
          date: 'Tonight',
          time: '7:00 PM - 9:00 PM EST',
          location: 'SoHo Innovation Hub, NYC',
          attendeesCount: 48,
          imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
          category: 'Social',
          accentColor: AppColors.emerald,
          description:
              'An intimate evening breakdown of early stage mechanics, high leverage decisions, and overcoming zero-to-one velocity hurdles with real founders.',
          xpReward: 200,
          isRsvpd: true,
        ),
        Event(
          id: '2',
          communityId: '2',
          title: 'Deep Work Sprint & Architecture Review',
          host: 'Marcus T. (Staff Eng)',
          date: 'Tomorrow',
          time: '10:00 AM - 1:00 PM EST',
          location: 'Virtual • Discord Stage 01',
          attendeesCount: 32,
          imageUrl: 'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=800',
          category: 'Tech',
          accentColor: AppColors.questBlue,
          description:
              'Focus blocks with live pair code reviews, architecture teardowns, and real-time state machine modeling.',
          xpReward: 150,
          isRsvpd: false,
        ),
        Event(
          id: '3',
          communityId: '3',
          title: 'Fluid Interfaces & Design Token Masterclass',
          host: 'Elena V. (Design Lead)',
          date: 'Sat, Mar 28',
          time: '2:00 PM - 4:30 PM EST',
          location: 'Flatiron Design Studio',
          attendeesCount: 64,
          imageUrl: 'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
          category: 'Design',
          accentColor: AppColors.auroraPurple,
          description:
              'Hands-on workshop exploring tactile micro-interactions, responsive tokens, dynamic shadows, and high-fidelity transitions in Flutter.',
          xpReward: 250,
          isRsvpd: false,
        ),
      ],
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void toggleRsvp(String eventId) {
    final updatedRsvps = Set<String>.from(state.rsvpdEventIds);
    final isCurrentlyRsvpd = updatedRsvps.contains(eventId);

    if (isCurrentlyRsvpd) {
      updatedRsvps.remove(eventId);
    } else {
      updatedRsvps.add(eventId);
    }

    final updatedEvents = state.events.map((e) {
      if (e.id == eventId) {
        return e.copyWith(
          attendeesCount: isCurrentlyRsvpd ? e.attendeesCount - 1 : e.attendeesCount + 1,
          isRsvpd: !isCurrentlyRsvpd,
        );
      }
      return e;
    }).toList();

    state = state.copyWith(
      events: updatedEvents,
      rsvpdEventIds: updatedRsvps,
    );
  }

  void addEvent(Event newEvent) {
    state = state.copyWith(
      events: [newEvent, ...state.events],
    );
  }

  Event? getEventById(String eventId) {
    try {
      final cleanId = eventId.replaceAll(RegExp(r'^e'), '');
      return state.events.firstWhere(
        (e) => e.id == eventId || e.id == cleanId || 'e${e.id}' == eventId,
      );
    } catch (_) {
      return state.events.isNotEmpty ? state.events.first : null;
    }
  }
}

final eventsProvider = NotifierProvider<EventsNotifier, EventsState>(() {
  return EventsNotifier();
});
