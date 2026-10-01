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
      final userMetadata = _supabase.auth.currentUser?.userMetadata;
      final defaultName = userMetadata?['full_name'] as String? ?? 'Explorer';
      final defaultProfile = UserState.initial().copyWith(
        name: defaultName,
        initials: defaultName.isNotEmpty ? defaultName[0].toUpperCase() : 'Q',
      );
      await updateUser(defaultProfile);
      return defaultProfile;
    }

    // Fetch daily quests separately
    final dailyQuestsResponse = await _supabase
        .from('daily_quests')
        .select()
        .eq('userId', userId);

    final List<QuestItem> dailyQuests = (dailyQuestsResponse as List<dynamic>)
        .map((q) => QuestItem.fromJson(q as Map<String, dynamic>))
        .toList();

    return UserState.fromJson(response).copyWith(dailyQuests: dailyQuests);
  }

  @override
  Future<void> updateUser(UserState user) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Build profile update — write all known column variants for resilience
    // across the split migration eras. See docs/architecture/11_database_schema_reference.md
    // for the architecture decision on intentional dual-column design.
    final profileData = <String, dynamic>{
      'id': userId,
      // Name — camelCase (20260805 migration) + snake_case (20260821 migration)
      'name': user.name,
      'full_name': user.name,
      // Avatar standardized to what edge functions use
      'avatar_url': user.avatarUrl,
      // Standard snake_case columns
      'username': user.username,
      'bio': user.bio,
      'onboarding_completed': user.onboardingCompleted,
    };

    try {
      await _supabase.functions.invoke(
        'update-profile',
        body: profileData,
      );
    } catch (_) {
      // Fallback to direct upsert in case of edge function unavailability
      await _supabase.from('profiles').upsert(profileData);
    }

    // Upsert daily quests. Server generates UUID if quest has a non-UUID id
    // by omitting the id field on insert. On subsequent saves, the server-
    // returned UUID is used for upsert, preventing orphaned row accumulation.
    for (final quest in user.dailyQuests) {
      final questData = quest.toJson();
      questData['userId'] = userId;

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
