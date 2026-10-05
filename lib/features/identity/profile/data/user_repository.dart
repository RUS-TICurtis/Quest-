import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/features/identity/profile/domain/username_rules.dart';
import 'user_provider.dart';

/// Thrown when the backend rejects a username because another account owns it.
class UsernameTakenException implements Exception {
  const UsernameTakenException();
  @override
  String toString() => 'That username is already taken.';
}

/// Thrown for profile writes that fail for a reason the user can act on.
class ProfileSaveException implements Exception {
  final String message;
  const ProfileSaveException(this.message);
  @override
  String toString() => message;
}

abstract class UserRepository {
  Future<UserState> getUser(String userId);
  Future<void> updateUser(UserState user);

  /// Backend-authoritative availability check. Advisory only: the unique index
  /// decides at write time, so callers must still handle [UsernameTakenException].
  Future<bool> isUsernameAvailable(String username);
}

class SupabaseUserRepository implements UserRepository {
  final SupabaseClient _supabase;

  SupabaseUserRepository(this._supabase);

  @override
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = UsernameRules.normalize(username);
    final result = await _supabase.rpc(
      'check_username_available',
      params: {'p_username': normalized},
    );
    return result == true;
  }

  @override
  Future<UserState> getUser(String userId) async {
    if (userId.isEmpty) return UserState.initial();

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      // First sign-in: create the profile from the identity provider's data.
      final userMetadata = _supabase.auth.currentUser?.userMetadata;
      final defaultName =
          (userMetadata?['full_name'] ?? userMetadata?['name']) as String? ??
          'Explorer';
      final defaultProfile = UserState.initial().copyWith(
        name: defaultName,
        initials: defaultName.isNotEmpty ? defaultName[0].toUpperCase() : 'Q',
        avatarUrl: userMetadata?['avatar_url'] as String?,
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
    final current = _supabase.auth.currentUser;
    final userId = current?.id;
    if (userId == null) return;
    // Guests never own a profile row (also enforced by RLS + edge function).
    if (current!.isAnonymous) return;

    // Only user-editable fields are sent. XP/level/role/badges are server-owned
    // and silently ignored by the edge function and DB trigger.
    final profileData = <String, dynamic>{
      'name': user.name,
      'avatar_url': user.avatarUrl,
      'username': user.username,
      'bio': user.bio,
      'onboarding_completed': user.onboardingCompleted,
      'archetypes': user.archetypes,
    };

    try {
      await _supabase.functions.invoke('update-profile', body: profileData);
    } on FunctionException catch (e) {
      if (e.status == 409) throw const UsernameTakenException();
      final details = e.details;
      final message = details is Map ? details['message'] as String? : null;
      throw ProfileSaveException(message ?? 'Could not save your profile.');
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
