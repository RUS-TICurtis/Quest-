import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leaderboard_provider.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getMembers();
  Future<List<GuildRanking>> getGuilds();
}

class SupabaseLeaderboardRepository implements LeaderboardRepository {
  final SupabaseClient _supabase;

  SupabaseLeaderboardRepository(this._supabase);

  @override
  Future<List<LeaderboardEntry>> getMembers() async {
    final response = await _supabase
        .from('leaderboard')
        .select()
        .order('rank', ascending: true);

    return (response as List<dynamic>)
        .map((entry) => LeaderboardEntry.fromJson(entry))
        .toList();
  }

  @override
  Future<List<GuildRanking>> getGuilds() async {
    // For now returning mock data since guilds wasn't in our schema yet
    return [
      const GuildRanking(
        rank: 1,
        id: '1',
        name: 'Startup Founders',
        category: 'Business',
        membersCount: 142,
        weeklyXp: 125000,
        bannerUrl: 'https://images.unsplash.com/photo-1556761175-4b46a572b786?w=500',
      ),
      const GuildRanking(
        rank: 2,
        id: '2',
        name: 'Local Devs',
        category: 'Technology',
        membersCount: 89,
        weeklyXp: 98000,
        bannerUrl: 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500',
      ),
    ];
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return SupabaseLeaderboardRepository(Supabase.instance.client);
});
