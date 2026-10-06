import 'package:flutter/foundation.dart';
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

  Future<void> joinCommunity(String userId, String communityId);
  Future<void> leaveCommunity(String userId, String communityId);
  Future<void> rsvpEvent(String userId, String eventId, {String status = 'going'});
  Future<void> cancelRsvpEvent(String userId, String eventId);
  Future<void> awardXp(String userId, int amount, String reason);
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

    // Fetch daily quests, community memberships, and event RSVPs in parallel
    final results = await Future.wait([
      _supabase
          .from('daily_quests')
          .select()
          .eq('userId', userId)
          .then((res) => res as List<dynamic>)
          .catchError((_) => <dynamic>[]),
      _supabase
          .from('community_members')
          .select('community_id')
          .eq('user_id', userId)
          .then((res) => res as List<dynamic>)
          .catchError((_) => <dynamic>[]),
      _supabase
          .from('event_rsvps')
          .select('event_id')
          .eq('user_id', userId)
          .then((res) => res as List<dynamic>)
          .catchError((_) => <dynamic>[]),
    ]);

    final List<QuestItem> dailyQuests = results[0]
        .map((q) => QuestItem.fromJson(q as Map<String, dynamic>))
        .toList();

    final List<String> joinedCommunityIds = results[1]
        .map((m) => m['community_id'].toString())
        .toList();

    final List<String> rsvpdEventIds = results[2]
        .map((r) => r['event_id'].toString())
        .toList();

    return UserState.fromJson(response).copyWith(
      dailyQuests: dailyQuests,
      joinedCommunityIds: joinedCommunityIds,
      rsvpdEventIds: rsvpdEventIds,
    );
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

    // Upsert daily quests.
    for (final quest in user.dailyQuests) {
      final questData = quest.toJson();
      questData['userId'] = userId;

      final bool hasServerUuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(questData['id'] as String? ?? '');

      if (hasServerUuid) {
        await _supabase.from('daily_quests').upsert(questData);
      } else {
        questData.remove('id');
        await _supabase.from('daily_quests').insert(questData);
      }
    }
  }

  @override
  Future<void> joinCommunity(String userId, String communityId) async {
    await _supabase.from('community_members').upsert({
      'community_id': communityId,
      'user_id': userId,
      'role': 'member',
    }, onConflict: 'community_id,user_id');
  }

  @override
  Future<void> leaveCommunity(String userId, String communityId) async {
    await _supabase
        .from('community_members')
        .delete()
        .eq('community_id', communityId)
        .eq('user_id', userId);
  }

  @override
  Future<void> rsvpEvent(
    String userId,
    String eventId, {
    String status = 'going',
  }) async {
    await _supabase.from('event_rsvps').upsert({
      'event_id': eventId,
      'user_id': userId,
      'status': status,
    }, onConflict: 'event_id,user_id');
  }

  @override
  Future<void> cancelRsvpEvent(String userId, String eventId) async {
    await _supabase
        .from('event_rsvps')
        .delete()
        .eq('event_id', eventId)
        .eq('user_id', userId);
  }

  @override
  Future<void> awardXp(String userId, int amount, String reason) async {
    try {
      await _supabase.rpc('award_xp', params: {
        'p_user_id': userId,
        'p_amount': amount,
        'p_reason': reason,
      });
    } catch (e) {
      debugPrint('[SupabaseUserRepository] awardXp notice: $e');
    }
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return SupabaseUserRepository(Supabase.instance.client);
});
