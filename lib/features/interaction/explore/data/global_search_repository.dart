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

  const GlobalSearchResults.empty()
      : users = const [],
        quests = const [],
        events = const [],
        communities = const [];

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
      return const GlobalSearchResults.empty();
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
      return const [];
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
      return const [];
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
      return const [];
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
      return const [];
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
        users: users,
        events: events,
        communities: communities,
        quests: quests,
      );
    } catch (e) {
      debugPrint('[GlobalSearchRepository] getTrending notice: $e');
      return const GlobalSearchResults.empty();
    }
  }
}
