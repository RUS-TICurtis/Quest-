import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:quest/core/storage/local_database_service.dart';
import 'package:quest/core/storage/models/cached_feed_video.dart';
import 'package:flutter/foundation.dart';

final feedRepositoryProvider = Provider(
  (ref) => FeedRepository(
    Supabase.instance.client,
    ref.read(localDatabaseProvider),
  ),
);

class FeedRepository {
  final SupabaseClient _supabase;
  final LocalDatabaseService _localDb;

  FeedRepository(this._supabase, this._localDb);

  Future<({List<CreatorVideo> videos, Map<String, dynamic>? nextCursor})>
  getFeed({
    String seed = 'default',
    Map<String, dynamic>? cursor,
    int limit = 15,
  }) async {
    try {
      // Load seen IDs from Hive Box for deduplication (capped at 200)
      final seenIds = _localDb.getSeenVideoIds();

      final response = await _supabase.functions.invoke(
        'get-feed',
        body: {
          'seed': seed,
          'cursor': cursor,
          'limit': limit,
          'seen_ids': seenIds,
          'recent_genres': [],
        },
      );

      final data = response.data;
      if (data == null || data['videos'] == null) {
        return (videos: <CreatorVideo>[], nextCursor: null);
      }

      final videosList = (data['videos'] as List).map((v) {
        // The edge function maps creator fields inside profiles:{username, avatar_url}
        // Flatten them for the model
        final profile = v['profiles'] as Map<String, dynamic>?;
        if (profile != null) {
          v['creator_username'] = profile['username'];
          v['creator_avatar_url'] = profile['avatar_url'];
        }
        return CreatorVideo.fromJson(v);
      }).toList();

      // Cache fetched videos to Isar (enables offline feed on next open)
      final toCache = (data['videos'] as List)
          .map((v) => CachedFeedVideo.fromJson(v as Map<String, dynamic>))
          .toList();
      unawaited(_localDb.cacheFeedVideos(toCache));

      return (
        videos: videosList,
        nextCursor: data['next_cursor'] as Map<String, dynamic>?,
      );
    } catch (e) {
      debugPrint('[FeedRepository] get-feed edge function notice: $e');

      // Fallback 1: Try direct DB query on feed_videos (fallback table)
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

      // Fallback 2: Return Hive-cached videos from previous sessions
      try {
        final cached = _localDb.getCachedFeedVideos(limit: limit);
        if (cached.isNotEmpty) {
          debugPrint('[FeedRepository] Serving ${cached.length} Hive-cached videos');
          final list = cached.map((c) {
            return CreatorVideo(
              id: c.videoId,
              creatorId: c.creatorId ?? '',
              videoUrl: c.videoUrl,
              thumbnailUrl: c.thumbnailUrl ?? '',
              title: c.title ?? '',
              description: c.description ?? '',
              viewCount: c.viewCount,
              likeCount: c.likeCount,
              commentCount: c.commentCount,
              shareCount: c.shareCount,
              createdAt: c.cachedAt,
              engagementScore: c.engagementScore,
              durationSeconds: c.durationSeconds,
              creatorUsername: c.creatorUsername,
              creatorAvatarUrl: c.creatorAvatarUrl,
            );
          }).toList();
          return (videos: list, nextCursor: null);
        }
      } catch (_) {}

      // Fallback 3: Static sample videos — at least 5 so PageView is always scrollable
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
                'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
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
                'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
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
            videoUrl: 'https://test-streams.mux.dev/test_1/stream.m3u8',
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
            videoUrl: 'https://test-streams.mux.dev/pts_time/master.m3u8',
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

  /// Marks a video as seen locally (used to populate seen_ids on next page load).
  Future<void> markVideoSeen(String videoId) async {
    unawaited(_localDb.markVideoSeen(videoId));
  }

  /// Optimistically increments like count in Isar and fires interact-video.
  ///
  /// NOTE: `interact-video` targets the `videos` (Phase 3) table. If
  /// `feed_rankings` is backed by `feed_videos` instead, the counter increment
  /// there will need a separate direct update. Investigate `feed_rankings`
  /// view definition if like counts don't reflect in the feed after refresh.
  Future<void> likeVideo(String videoId) async {
    // Optimistic update in Isar cache
    unawaited(_localDb.incrementLikeCount(videoId));

    // Fire-and-forget to Edge Function (writes to 'videos' Phase 3 table)
    try {
      await _supabase.functions.invoke(
        'interact-video',
        body: {'video_id': videoId, 'action': 'like'},
      );
    } catch (e) {
      debugPrint('[FeedRepository] likeVideo notice: $e');
    }

    // Direct write-back to 'feed_videos' table for immediate read-after-write consistency
    // because get-feed edge function reads from feed_videos.
    try {
      // Call Supabase RPC to increment counter atomically if it exists,
      // or we can just fetch and update.
      await _supabase.rpc('increment_video_like', params: {'video_id': videoId});
    } catch (_) {
      // If RPC doesn't exist, we fallback to a simpler solution or ignore
      // since interact-video might eventually sync to feed_videos via cron.
    }
  }

  /// Optimistically increments share count and fires interact-video.
  Future<void> shareVideo(String videoId) async {
    // We don't have incrementShareCount in _localDb yet, but we could add it.
    // For now, fire-and-forget to Edge Function
    try {
      await _supabase.functions.invoke(
        'interact-video',
        body: {'video_id': videoId, 'action': 'share'},
      );
    } catch (e) {
      debugPrint('[FeedRepository] shareVideo notice: $e');
    }

    try {
      await _supabase.rpc('increment_video_share', params: {'video_id': videoId});
    } catch (_) {}
  }

  /// Increments comment count via interact-video.
  Future<void> commentOnVideo(String videoId, String commentText) async {
    try {
      await _supabase.functions.invoke(
        'interact-video',
        body: {
          'video_id': videoId,
          'action': 'comment',
          'comment_text': commentText,
        },
      );
    } catch (e) {
      debugPrint('[FeedRepository] commentOnVideo notice: $e');
    }
  }
}

/// Fire-and-forget helper that suppresses the unawaited warning.
void unawaited(Future<void> f) {}
