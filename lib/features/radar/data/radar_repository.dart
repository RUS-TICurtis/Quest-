import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'radar_provider.dart';

abstract class RadarRepository {
  Future<List<HubLocation>> getHubs();
  Future<List<RadarMember>> getNearbyMembers();
}

class SupabaseRadarRepository implements RadarRepository {
  final SupabaseClient _supabase;

  SupabaseRadarRepository(this._supabase);

  @override
  Future<List<HubLocation>> getHubs() async {
    final response = await _supabase.from('radar_nodes').select();
    
    return (response as List<dynamic>)
        .map((node) => HubLocation.fromJson(node))
        .toList();
  }

  @override
  Future<List<RadarMember>> getNearbyMembers() async {
    // Return mock data for now since we don't have a radar_members table
    // PostGIS isn't fully set up yet in our schema for real-time proximity
    return const [
      RadarMember(
        id: 'mem_1',
        name: 'Jordan Reed',
        initials: 'JR',
        avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        archetype: 'Builder',
        distanceFeet: 35,
        currentHubId: 'hub_1',
        status: 'Building real-time WebRTC audio pipeline',
        angleRatio: 0.15,
        radiusRatio: 0.35,
      ),
      RadarMember(
        id: 'mem_2',
        name: 'Maya Lin',
        initials: 'ML',
        avatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
        archetype: 'Strategist',
        distanceFeet: 60,
        currentHubId: 'hub_1',
        status: 'Reviewing Q3 GTM strategy',
        angleRatio: 0.45,
        radiusRatio: 0.65,
      ),
    ];
  }
}

final radarRepositoryProvider = Provider<RadarRepository>((ref) {
  return SupabaseRadarRepository(Supabase.instance.client);
});
