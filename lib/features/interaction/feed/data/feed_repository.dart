import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:flutter/foundation.dart';

final feedRepositoryProvider = Provider((ref) => FeedRepository(Supabase.instance.client));

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository(this._supabase);

  Future<({List<CreatorVideo> videos, Map<String, dynamic>? nextCursor})> getFeed({
    String seed = 'default',
    Map<String, dynamic>? cursor,
    int limit = 15,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-feed',
        body: {
          'seed': seed,
          'cursor': cursor,
          'limit': limit,
          'seen_ids': [],
          'recent_genres': [],
        },
      );

      final data = response.data;
      if (data == null || data['videos'] == null) {
        return (videos: <CreatorVideo>[], nextCursor: null);
      }

      final videosList = (data['videos'] as List).map((v) {
        // Quest's CreatorVideo expects creator_username and creator_avatar_url
        // The edge function maps them inside profiles, but wait:
        // The edge function maps them as `profiles: { username, avatar_url }`
        // Let's flatten them for the model:
        final profile = v['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          v['creator_username'] = profile['username'];
          v['creator_avatar_url'] = profile['avatar_url'];
        }
        return CreatorVideo.fromJson(v);
      }).toList();

      return (
        videos: videosList,
        nextCursor: data['next_cursor'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('[FeedRepository] get-feed error: $e');
      rethrow;
    }
  }
}
