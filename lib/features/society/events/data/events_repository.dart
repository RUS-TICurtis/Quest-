import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'events_provider.dart';
abstract class EventsRepository {
  Future<List<Event>> getEvents();
  Future<void> updateEvent(Event event);
}

class MockEventsRepository implements EventsRepository {
  List<Event> _mockEvents = [
    Event(
      id: '1',
      communityId: '1',
      title: 'Founder Fireside: Zero to Scale',
      host: 'Sarah Chen (Y Combinator)',
      date: 'Tonight',
      time: '7:00 PM - 9:00 PM EST',
      location: 'SoHo Innovation Hub, NYC',
      attendeesCount: 48,
      imageUrl:
          'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
      category: 'Social',
      accentColor: AppColors.emerald,
      description:
          'An intimate evening breakdown of early stage mechanics, high leverage decisions, and overcoming zero-to-one velocity hurdles with real founders.',
      xpReward: 200,
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
      imageUrl:
          'https://images.unsplash.com/photo-1517048676732-d65bc937f952?w=800',
      category: 'Tech',
      accentColor: AppColors.questBlue,
      description:
          'Focus blocks with live pair code reviews, architecture teardowns, and real-time state machine modeling.',
      xpReward: 150,
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
      imageUrl:
          'https://images.unsplash.com/photo-1531403009284-440f080d1e12?w=800',
      category: 'Design',
      accentColor: AppColors.auroraPurple,
      description:
          'Hands-on workshop exploring tactile micro-interactions, responsive tokens, dynamic shadows, and high-fidelity transitions in Flutter.',
      xpReward: 250,
    ),
  ];

  @override
  Future<List<Event>> getEvents() async {
    await Future.delayed(Duration(milliseconds: 500));
    return List.from(_mockEvents);
  }

  @override
  Future<void> updateEvent(Event event) async {
    await Future.delayed(Duration(milliseconds: 200));
    final index = _mockEvents.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      final updatedList = List<Event>.from(_mockEvents);
      updatedList[index] = event;
      _mockEvents = updatedList;
    }
  }
}

class SupabaseEventsRepository implements EventsRepository {
  final SupabaseClient _client;

  SupabaseEventsRepository(this._client);

  @override
  Future<List<Event>> getEvents() async {
    final data = await _client.from('events').select();
    return data.map((json) => Event.fromJson(json)).toList();
  }

  @override
  Future<void> updateEvent(Event event) async {
    await _client.from('events').update(event.toJson()).eq('id', event.id);
  }
}

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return SupabaseEventsRepository(Supabase.instance.client);
});
