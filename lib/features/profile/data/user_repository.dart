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
    // If it's the mock 'current_user' ID, fetch the actual logged in user
    final queryId = userId == 'current_user' ? _supabase.auth.currentUser?.id : userId;
    
    if (queryId == null) {
      return UserState.initial();
    }

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', queryId)
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

    final dailyQuestsResponse = await _supabase
        .from('daily_quests')
        .select()
        .eq('userId', queryId);

    final List<QuestItem> dailyQuests = (dailyQuestsResponse as List<dynamic>)
        .map((q) => QuestItem.fromJson(q as Map<String, dynamic>))
        .toList();

    return UserState.fromJson(response).copyWith(dailyQuests: dailyQuests);
  }

  @override
  Future<void> updateUser(UserState user) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final profileData = user.toJson();
    profileData.remove('dailyQuests'); // handled separately
    profileData['id'] = userId;

    await _supabase.from('profiles').upsert(profileData);

    for (final quest in user.dailyQuests) {
      final questData = quest.toJson();
      questData['userId'] = userId;
      // If it's a mock UUID from initial state without a valid UUID format, 
      // we might want to let Postgres generate it, but we'll try to upsert.
      // Assuming mock IDs are '1', '2' which aren't UUIDs. 
      // If so, we might need to ignore ID on insert.
      try {
        await _supabase.from('daily_quests').upsert(questData);
      } catch (e) {
        // If UUID error, try inserting without ID
        questData.remove('id');
        await _supabase.from('daily_quests').insert(questData);
      }
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SupabaseUserRepository(Supabase.instance.client);
});
