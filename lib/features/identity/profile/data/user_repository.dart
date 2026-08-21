import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_provider.dart';

abstract class UserRepository {
  Future<UserState> getUser(String userId);
  Future<void> updateUser(UserState user);
}

class SupabaseUserRepository implements UserRepository {
  final SupabaseClient _supabase;

  SupabaseUserRepository(this._supabase);

  @override
  Future<UserState> getUser(String userId) async {
    if (userId.isEmpty) return UserState.initial();

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      // Create profile if it doesn't exist
      final defaultProfile = UserState.initial().copyWith(
        name: 'New Player',
        initials: 'NP',
      );
      await updateUser(defaultProfile);
      return defaultProfile;
    }

    // Fetch daily quests separately
    final dailyQuestsResponse = await _supabase
        .from('daily_quests')
        .select()
        .eq('user_id', userId);

    final List<QuestItem> dailyQuests = (dailyQuestsResponse as List<dynamic>)
        .map((q) => QuestItem.fromJson(q as Map<String, dynamic>))
        .toList();

    return UserState.fromJson(response).copyWith(dailyQuests: dailyQuests);
  }

  @override
  Future<void> updateUser(UserState user) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Update profile (exclude quests, handled separately)
    final profileData = user.toJson();
    profileData.remove('dailyQuests');
    profileData['id'] = userId;

    await _supabase.from('profiles').upsert(profileData);

    // Upsert daily quests. Server generates UUID if quest has a non-UUID id
    // by omitting the id field on insert. On subsequent saves, the server-
    // returned UUID is used for upsert, preventing orphaned row accumulation.
    for (final quest in user.dailyQuests) {
      final questData = quest.toJson();
      questData['user_id'] = userId;

      // Determine if the quest has a real server UUID or a client-side
      // placeholder (e.g. '1', '2'). A real UUID is 36 chars with dashes.
      final bool hasServerUuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(questData['id'] as String? ?? '');

      if (hasServerUuid) {
        await _supabase.from('daily_quests').upsert(questData);
      } else {
        // Remove client placeholder — let Postgres generate a UUID.
        questData.remove('id');
        await _supabase.from('daily_quests').insert(questData);
      }
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SupabaseUserRepository(Supabase.instance.client);
});
