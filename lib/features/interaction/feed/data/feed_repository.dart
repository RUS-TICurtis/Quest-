import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:flutter/foundation.dart';

final feedRepositoryProvider = Provider(
  (ref) => FeedRepository(Supabase.instance.client),
);

class FeedRepository {
  final SupabaseClient _supabase;

  FeedRepository(this._supabase);

  Future<({List<CreatorVideo> videos, Map<String, dynamic>? nextCursor})>
  getFeed({
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
      debugPrint('[FeedRepository] get-feed edge function notice: $e');
      try {
        final dbVideos = await _supabase
            .from('feed_videos')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);
        if (dbVideos.isNotEmpty) {
          final list = dbVideos.map((v) => CreatorVideo.fromJson(v)).toList();
          return (videos: list, nextCursor: null);
        }
      } catch (dbErr) {
        debugPrint('[FeedRepository] DB fallback notice: $dbErr');
      }

      // Default fallback videos – at least 5 so PageView is always scrollable
      return (
        videos: [
          CreatorVideo(
            id: 'v_sample_1',
            creatorId: 'c1',
            videoUrl: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400',
            title: 'Big Buck Bunny (HLS)',
            description: 'Open-source HLS stream via Mux test CDN.',
            viewCount: 142,
            likeCount: 38,
            commentCount: 5,
            shareCount: 12,
            createdAt: DateTime.now(),
            engagementScore: 0.95,
            durationSeconds: 60,
            creatorUsername: 'quest_team',
            creatorAvatarUrl:
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
          ),
          CreatorVideo(
            id: 'v_sample_2',
            creatorId: 'c2',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
            title: 'Big Buck Bunny',
            description: 'Classic open-source animation — MP4 direct.',
            viewCount: 3200,
            likeCount: 890,
            commentCount: 41,
            shareCount: 120,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            engagementScore: 0.87,
            durationSeconds: 596,
            creatorUsername: 'blender_foundation',
            creatorAvatarUrl:
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
          ),
          CreatorVideo(
            id: 'v_sample_3',
            creatorId: 'c3',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1551884170-09fb70a3a2ed?w=400',
            title: 'Elephants Dream',
            description: 'First open-movie project by the Blender community.',
            viewCount: 1820,
            likeCount: 430,
            commentCount: 22,
            shareCount: 67,
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
            engagementScore: 0.78,
            durationSeconds: 654,
            creatorUsername: 'blender_org',
            creatorAvatarUrl:
                'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=200',
          ),
          CreatorVideo(
            id: 'v_sample_4',
            creatorId: 'c4',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1519817650390-64a93db51149?w=400',
            title: 'For Bigger Blazes',
            description: 'Sample video for bigger displays.',
            viewCount: 560,
            likeCount: 112,
            commentCount: 8,
            shareCount: 30,
            createdAt: DateTime.now().subtract(const Duration(hours: 8)),
            engagementScore: 0.70,
            durationSeconds: 15,
            creatorUsername: 'google_samples',
            creatorAvatarUrl:
                'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
          ),
          CreatorVideo(
            id: 'v_sample_5',
            creatorId: 'c5',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
            thumbnailUrl:
                'https://images.unsplash.com/photo-1484821582734-6c6c9f99a672?w=400',
            title: 'Subaru Outback',
            description: 'On street and dirt — sample outdoor video.',
            viewCount: 920,
            likeCount: 205,
            commentCount: 14,
            shareCount: 45,
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
            engagementScore: 0.65,
            durationSeconds: 60,
            creatorUsername: 'car_life',
            creatorAvatarUrl:
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          ),
        ],
        nextCursor: null,
      );
    }
  }
}
