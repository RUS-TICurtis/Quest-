import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'beacon_model.dart';
import 'radar_provider.dart';

abstract class RadarRepository {
  Future<List<HubLocation>> getHubs();
  Future<List<RadarMember>> getNearbyMembers();
  Future<List<BeaconModel>> getActiveBeacons({String? hubId});
  Future<void> createBeacon(BeaconModel beacon);
  Future<void> joinBeacon(String beaconId, String userId, String userAvatar);
}

class SupabaseRadarRepository implements RadarRepository {
  final SupabaseClient _supabase;

  SupabaseRadarRepository(this._supabase);

  @override
  Future<List<HubLocation>> getHubs() async {
    try {
      final response = await _supabase.from('radar_nodes').select();
      final list = (response as List<dynamic>)
          .map((node) => HubLocation.fromJson(node))
          .toList();
      if (list.isNotEmpty) return list;
    } catch (_) {
      // Table may not be provisioned or network is offline
    }

    return [
      HubLocation(
        id: 'hub_1',
        name: 'City Innovation Hub',
        address: 'Downtown Tech District',
        category: 'Technology & Startups',
        activeMembersCount: 0,
        distanceMiles: 0.3,
        isVerified: true,
        xpBonus: 150,
        imageUrl:
            'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
      ),
    ];
  }

  @override
  Future<List<RadarMember>> getNearbyMembers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      final query = _supabase
          .from('profiles')
          .select('id, name, username, avatar_url, bio, archetypes');

      final response = currentUserId != null
          ? await query.neq('id', currentUserId).limit(10)
          : await query.limit(10);

      final members = <RadarMember>[];
      var index = 0;
      for (final row in response as List<dynamic>) {
        final id = row['id']?.toString() ?? 'mem_$index';
        final name = row['name']?.toString() ??
            row['username']?.toString() ??
            'Builder';
        final avatar = row['avatar_url']?.toString() ??
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200';
        final bio = row['bio']?.toString() ?? 'Active on Quest radar';
        final archetypes = row['archetypes'] as List<dynamic>?;
        final archetype = (archetypes != null && archetypes.isNotEmpty)
            ? archetypes.first.toString()
            : 'Adventurer';

        final initials = name.isNotEmpty
            ? name
                .split(' ')
                .map((e) => e.isNotEmpty ? e[0] : '')
                .take(2)
                .join()
                .toUpperCase()
            : 'Q';

        // Deterministic radial coordinates
        final angleRatio = ((id.hashCode.abs() % 100) / 100.0);
        final radiusRatio = 0.25 + ((id.length.hashCode.abs() % 55) / 100.0);
        final distanceFeet = 25 + (index * 15);

        members.add(
          RadarMember(
            id: id,
            name: name,
            initials: initials.isNotEmpty ? initials : 'Q',
            avatar: avatar,
            archetype: archetype,
            distanceFeet: distanceFeet,
            currentHubId: 'hub_1',
            status: bio,
            angleRatio: angleRatio,
            radiusRatio: radiusRatio,
          ),
        );
        index++;
      }

      return members;
    } catch (_) {
      return const [];
    }
  }

  // In-memory cache for beacons dropped/joined during current session
  final List<BeaconModel> _localBeacons = [];

  @override
  Future<List<BeaconModel>> getActiveBeacons({String? hubId}) async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      var query = _supabase.from('beacons').select().gt('expires_at', nowUtc);
      if (hubId != null) {
        query = query.eq('hub_id', hubId);
      }
      final response = await query;
      return (response as List<dynamic>)
          .map((row) => BeaconModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Table may not yet be provisioned or offline
    }

    // Filter local active non-expired beacons
    return _localBeacons
        .where((b) => !b.isExpired && (hubId == null || b.hubId == hubId))
        .toList();
  }

  @override
  Future<void> createBeacon(BeaconModel beacon) async {
    _localBeacons.insert(0, beacon);
    try {
      await _supabase.from('beacons').insert(beacon.toJson());
    } catch (_) {
      // Graceful local offline fallback
    }
  }

  @override
  Future<void> joinBeacon(
    String beaconId,
    String userId,
    String userAvatar,
  ) async {
    final index = _localBeacons.indexWhere((b) => b.id == beaconId);
    if (index != -1) {
      final b = _localBeacons[index];
      if (!b.attendeeIds.contains(userId)) {
        final updatedIds = [...b.attendeeIds, userId];
        final updatedAvatars = [...b.attendeeAvatars, userAvatar];
        _localBeacons[index] = b.copyWith(
          attendeeIds: updatedIds,
          attendeeAvatars: updatedAvatars,
        );
      }
    }

    try {
      final response = await _supabase
          .from('beacons')
          .select('attendee_ids, attendee_avatars')
          .eq('id', beaconId)
          .maybeSingle();

      if (response != null) {
        final existingIds = (response['attendee_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
        final existingAvatars = (response['attendee_avatars'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        if (!existingIds.contains(userId)) {
          existingIds.add(userId);
          existingAvatars.add(userAvatar);
          await _supabase.from('beacons').update({
            'attendee_ids': existingIds,
            'attendee_avatars': existingAvatars,
          }).eq('id', beaconId);
        }
      }
    } catch (_) {}
  }
}

final radarRepositoryProvider = Provider<RadarRepository>((ref) {
  return SupabaseRadarRepository(Supabase.instance.client);
});
