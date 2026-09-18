import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/features/society/events/data/events_provider.dart';

final globalSearchRepositoryProvider = Provider<GlobalSearchRepository>((ref) {
  return GlobalSearchRepository(Supabase.instance.client);
});

class UserSearchResult {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final List<String> archetypes;
  final int level;
  final double trustScore;
  final String trustLevel;

  UserSearchResult({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    this.bio,
    this.archetypes = const [],
    this.level = 1,
    this.trustScore = 50.0,
    this.trustLevel = 'Bronze',
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    // Handle trust scores join if present
    double score = 50.0;
    String level = 'Bronze';
    final trustData = json['user_trust_scores'];
    if (trustData is Map<String, dynamic>) {
      score = (trustData['score'] as num?)?.toDouble() ?? 50.0;
      level = trustData['level'] as String? ?? 'Bronze';
    } else if (trustData is List && trustData.isNotEmpty) {
      final first = trustData.first;
      if (first is Map<String, dynamic>) {
        score = (first['score'] as num?)?.toDouble() ?? 50.0;
        level = first['level'] as String? ?? 'Bronze';
      }
    }

    final rawArchetypes = json['archetypes'];
    final List<String> parsedArchetypes = [];
    if (rawArchetypes is List) {
      parsedArchetypes.addAll(rawArchetypes.map((e) => e.toString()));
    } else if (json['archetype'] is String) {
      parsedArchetypes.add(json['archetype'] as String);
    }

    return UserSearchResult(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? json['username'] as String? ?? 'Adventurer',
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      bio: json['bio'] as String?,
      archetypes: parsedArchetypes,
      level: (json['level'] as num?)?.toInt() ?? 1,
      trustScore: score,
      trustLevel: level,
    );
  }
}

class GlobalSearchResults {
  final List<UserSearchResult> users;
  final List<QuestItem> quests;
  final List<Event> events;
  final List<Community> communities;

  const GlobalSearchResults({
    this.users = const [],
    this.quests = const [],
    this.events = const [],
    this.communities = const [],
  });

  bool get isEmpty =>
      users.isEmpty && quests.isEmpty && events.isEmpty && communities.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

class GlobalSearchRepository {
  final SupabaseClient _supabase;

  GlobalSearchRepository(this._supabase);

  Future<GlobalSearchResults> searchAll({
    required String query,
    String? archetypeFilter,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return getTrending();
    }

    try {
      final results = await Future.wait([
        searchUsers(query: trimmed, archetype: archetypeFilter),
        searchQuests(trimmed),
        searchEvents(trimmed),
        searchCommunities(trimmed),
      ]);

      return GlobalSearchResults(
        users: results[0] as List<UserSearchResult>,
        quests: results[1] as List<QuestItem>,
        events: results[2] as List<Event>,
        communities: results[3] as List<Community>,
      );
    } catch (e) {
      debugPrint('[GlobalSearchRepository] searchAll error: $e');
      return _getFallbackSearchResults(trimmed, archetypeFilter);
    }
  }

  Future<List<UserSearchResult>> searchUsers({
    required String query,
    String? archetype,
  }) async {
    try {
      var dbQuery = _supabase
          .from('profiles')
          .select('id, name, username, avatar_url, bio, archetypes, level, user_trust_scores(score, level)')
          .or('name.ilike.%$query%,username.ilike.%$query%,bio.ilike.%$query%');

      final response = await dbQuery.limit(20);
      final list = (response as List)
          .map((item) => UserSearchResult.fromJson(item as Map<String, dynamic>))
          .toList();

      if (archetype != null && archetype.isNotEmpty && archetype != 'All') {
        return list.where((u) => u.archetypes.contains(archetype)).toList();
      }
      return list;
    } catch (e) {
      debugPrint('[GlobalSearchRepository] searchUsers notice: $e');
      return _getMockUsers()
          .where((u) {
            final matchesQuery = u.name.toLowerCase().contains(query.toLowerCase()) ||
                (u.username?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
                (u.bio?.toLowerCase().contains(query.toLowerCase()) ?? false);
            final matchesArchetype = archetype == null ||
                archetype.isEmpty ||
                archetype == 'All' ||
                u.archetypes.contains(archetype);
            return matchesQuery && matchesArchetype;
          })
          .toList();
    }
  }

  Future<List<QuestItem>> searchQuests(String query) async {
    try {
      final response = await _supabase
          .from('daily_quests')
          .select('id, title, xp, isDone')
          .ilike('title', '%$query%')
          .limit(20);

      return (response as List)
          .map((item) => QuestItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[GlobalSearchRepository] searchQuests notice: $e');
      return _getMockQuests()
          .where((q) => q.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<List<Event>> searchEvents(String query) async {
    try {
      final response = await _supabase
          .from('events')
          .select()
          .or('title.ilike.%$query%,description.ilike.%$query%,location.ilike.%$query%,category.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((item) => Event.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[GlobalSearchRepository] searchEvents notice: $e');
      return _getMockEvents()
          .where((e) =>
              e.title.toLowerCase().contains(query.toLowerCase()) ||
              e.description.toLowerCase().contains(query.toLowerCase()) ||
              e.location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<List<Community>> searchCommunities(String query) async {
    try {
      final response = await _supabase
          .from('communities')
          .select()
          .or('name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%')
          .limit(20);

      return (response as List)
          .map((item) => Community.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[GlobalSearchRepository] searchCommunities notice: $e');
      return _getMockCommunities()
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.description.toLowerCase().contains(query.toLowerCase()) ||
              c.category.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  Future<GlobalSearchResults> getTrending() async {
    try {
      final usersRes = await _supabase
          .from('profiles')
          .select('id, name, username, avatar_url, bio, archetypes, level, user_trust_scores(score, level)')
          .limit(6);
      final eventsRes = await _supabase.from('events').select().limit(4);
      final communitiesRes = await _supabase.from('communities').select().limit(4);
      final questsRes = await _supabase.from('daily_quests').select().limit(4);

      final users = (usersRes as List)
          .map((item) => UserSearchResult.fromJson(item as Map<String, dynamic>))
          .toList();
      final events = (eventsRes as List)
          .map((item) => Event.fromJson(item as Map<String, dynamic>))
          .toList();
      final communities = (communitiesRes as List)
          .map((item) => Community.fromJson(item as Map<String, dynamic>))
          .toList();
      final quests = (questsRes as List)
          .map((item) => QuestItem.fromJson(item as Map<String, dynamic>))
          .toList();

      return GlobalSearchResults(
        users: users.isNotEmpty ? users : _getMockUsers(),
        events: events.isNotEmpty ? events : _getMockEvents(),
        communities: communities.isNotEmpty ? communities : _getMockCommunities(),
        quests: quests.isNotEmpty ? quests : _getMockQuests(),
      );
    } catch (e) {
      debugPrint('[GlobalSearchRepository] getTrending fallback: $e');
      return GlobalSearchResults(
        users: _getMockUsers(),
        events: _getMockEvents(),
        communities: _getMockCommunities(),
        quests: _getMockQuests(),
      );
    }
  }

  GlobalSearchResults _getFallbackSearchResults(String query, String? archetype) {
    return GlobalSearchResults(
      users: _getMockUsers()
          .where((u) {
            final matchesQuery = u.name.toLowerCase().contains(query.toLowerCase()) ||
                (u.username?.toLowerCase().contains(query.toLowerCase()) ?? false);
            final matchesArchetype = archetype == null ||
                archetype.isEmpty ||
                archetype == 'All' ||
                u.archetypes.contains(archetype);
            return matchesQuery && matchesArchetype;
          })
          .toList(),
      quests: _getMockQuests()
          .where((q) => q.title.toLowerCase().contains(query.toLowerCase()))
          .toList(),
      events: _getMockEvents()
          .where((e) =>
              e.title.toLowerCase().contains(query.toLowerCase()) ||
              e.location.toLowerCase().contains(query.toLowerCase()))
          .toList(),
      communities: _getMockCommunities()
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.category.toLowerCase().contains(query.toLowerCase()))
          .toList(),
    );
  }

  List<UserSearchResult> _getMockUsers() {
    return [
      UserSearchResult(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Curtis',
        username: 'curtis_quest',
        avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
        bio: 'Explorer of digital realms and community builder.',
        archetypes: ['Adventurer', 'Creator'],
        level: 12,
        trustScore: 95.5,
        trustLevel: 'Platinum',
      ),
      UserSearchResult(
        id: '22222222-2222-2222-2222-222222222222',
        name: 'Jane Doe',
        username: 'jane_doe',
        avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
        bio: 'Building vibrant open communities and design systems.',
        archetypes: ['Leader', 'Connector'],
        level: 9,
        trustScore: 88.0,
        trustLevel: 'Gold',
      ),
      UserSearchResult(
        id: '33333333-3333-3333-3333-333333333333',
        name: 'John Smith',
        username: 'john_smith',
        avatarUrl: 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
        bio: 'Organizing epic local events, marathons, and coding quests.',
        archetypes: ['Organizer', 'Strategist'],
        level: 15,
        trustScore: 75.0,
        trustLevel: 'Silver',
      ),
    ];
  }

  List<QuestItem> _getMockQuests() {
    return [
      QuestItem(id: 'q1', title: 'Complete 1 Community Discussion', xp: 100, isDone: false),
      QuestItem(id: 'q2', title: 'RSVP to an Upcoming Event', xp: 150, isDone: true),
      QuestItem(id: 'q3', title: 'Explore 3 Video Creator Feeds', xp: 75, isDone: false),
      QuestItem(id: 'q4', title: 'Invite a Friend to Your Guild', xp: 200, isDone: false),
    ];
  }

  List<Event> _getMockEvents() {
    return [
      Event(
        id: '77777777-7777-7777-7777-777777777777',
        communityId: '44444444-4444-4444-4444-444444444444',
        title: 'AI Developers Meetup',
        host: 'Curtis',
        date: 'Tomorrow',
        time: '6:00 PM',
        location: 'San Francisco Innovation Hub',
        attendeesCount: 45,
        imageUrl: 'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=600',
        category: 'Tech',
        description: 'Hands-on demos of local LLMs and agent frameworks.',
        xpReward: 250,
      ),
      Event(
        id: '88888888-8888-8888-8888-888888888888',
        communityId: '55555555-5555-5555-5555-555555555555',
        title: 'Sunset Park 5K',
        host: 'John Smith',
        date: 'Saturday',
        time: '7:00 AM',
        location: 'Golden Gate Park',
        attendeesCount: 32,
        imageUrl: 'https://images.unsplash.com/photo-1552674605-db6ffd4facb5?w=600',
        category: 'Fitness',
        description: 'Scenic morning run followed by coffee and stretch.',
        xpReward: 150,
      ),
    ];
  }

  List<Community> _getMockCommunities() {
    return [
      Community(
        id: '44444444-4444-4444-4444-444444444444',
        name: 'Tech Innovators',
        description: 'A place for exploring emerging technology, AI agents, and next-gen tools.',
        category: 'Tech',
        memberCount: 245,
        tags: ['AI', 'Code', 'Web3'],
      ),
      Community(
        id: '55555555-5555-5555-5555-555555555555',
        name: 'Local Runners & Hikers',
        description: 'Weekly group runs, trail exploration, and fitness milestones.',
        category: 'Fitness',
        memberCount: 128,
        tags: ['Running', 'Outdoors', 'Health'],
      ),
    ];
  }
}
