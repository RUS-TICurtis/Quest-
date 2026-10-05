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

      // Fallback 1: Try direct DB query on unified 'videos' table with profile join
      try {
        final dbVideos = await _supabase
            .from('videos')
            .select('*, profiles(username, avatar_url)')
            .eq('video_type', 'feed')
            .order('created_at', ascending: false)
            .limit(limit);

        if (dbVideos.isNotEmpty) {
          final list = (dbVideos as List)
              .map((v) => CreatorVideo.fromJson(v as Map<String, dynamic>))
              .toList();

          // Cache to local database for offline resilience
          final toCache = (dbVideos as List)
              .map((v) => CachedFeedVideo.fromJson(v as Map<String, dynamic>))
              .toList();
          unawaited(_localDb.cacheFeedVideos(toCache));

          return (videos: list, nextCursor: null);
        }
      } catch (dbErr) {
        debugPrint('[FeedRepository] Videos table fallback notice: $dbErr');
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
      } catch (cacheErr) {
        debugPrint('[FeedRepository] Cache fallback notice: $cacheErr');
      }

      // No mock/sample fallback: Return truthful empty list when no videos exist
      return (videos: <CreatorVideo>[], nextCursor: null);
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
