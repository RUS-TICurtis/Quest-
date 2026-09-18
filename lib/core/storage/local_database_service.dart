import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:quest/core/storage/models/local_chat_room.dart';
import 'package:quest/core/storage/models/local_chat_message.dart';
import 'package:quest/core/storage/models/cached_feed_video.dart';
import 'package:quest/core/storage/models/cached_member_profile.dart';
import 'package:quest/core/storage/models/cached_story.dart';

final localDatabaseProvider = Provider<LocalDatabaseService>((ref) {
  throw UnimplementedError(
    'localDatabaseProvider must be overridden in ProviderScope',
  );
});

/// Unified local database service — all structured offline data lives here.
///
/// Caching layer assignments:
///   Hive Box 'chat_rooms'       — ChatRoom metadata (existing)
///   Hive Box 'chat_messages'    — ChatMessage records (existing)
///   Hive Box 'feed_video_cache' — Feed video stale-while-revalidate + seen-ID dedup (typeId 10)
///   Hive Box 'profile_cache'    — Member profile 15-min stale-while-revalidate (typeId 11)
///   Hive Box 'story_cache'      — Story 24-hour TTL cache (typeId 12)
///
/// NOTE: Isar was evaluated and rejected \u2014 isar 3.1.0+1 only supports Dart <3.0
/// and isar_community has no stable pub.dev release. See pubspec.yaml comment.
class LocalDatabaseService {
  // ── Chat boxes (existing) ─────────────────────────────────────────────────
  late Box<LocalChatRoom> chatRoomsBox;
  late Box<LocalChatMessage> chatMessagesBox;

  // ── New cache boxes ───────────────────────────────────────────────────────
  late Box<CachedFeedVideo> feedVideoBox;
  late Box<CachedMemberProfile> profileBox;
  late Box<CachedStory> storyBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register all type adapters — guard with isAdapterRegistered to survive hot restart
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(LocalChatRoomAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(LocalChatMessageAdapter());
    }
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(CachedFeedVideoAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(CachedMemberProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(CachedStoryAdapter());
    }

    chatRoomsBox =
        await Hive.openBox<LocalChatRoom>('chat_rooms');
    chatMessagesBox =
        await Hive.openBox<LocalChatMessage>('chat_messages');
    feedVideoBox =
        await Hive.openBox<CachedFeedVideo>('feed_video_cache');
    profileBox =
        await Hive.openBox<CachedMemberProfile>('profile_cache');
    storyBox =
        await Hive.openBox<CachedStory>('story_cache');
  }

  // ── Feed helpers ──────────────────────────────────────────────────────────

  /// Cache a batch of feed videos. Keyed by videoId.
  Future<void> cacheFeedVideos(List<CachedFeedVideo> videos) async {
    for (final v in videos) {
      await feedVideoBox.put(v.videoId, v);
    }
  }

  /// Returns up to [limit] cached feed videos ordered by cachedAt descending.
  List<CachedFeedVideo> getCachedFeedVideos({int limit = 15}) {
    final all = feedVideoBox.values.toList()
      ..sort((a, b) => b.cachedAt.compareTo(a.cachedAt));
    return all.take(limit).toList();
  }

  /// Returns IDs of videos the user has already seen (capped at 200).
  List<String> getSeenVideoIds() {
    return feedVideoBox.values
        .where((v) => v.hasSeen)
        .map((v) => v.videoId)
        .take(200)
        .toList();
  }

  /// Marks a video as seen in the local cache.
  Future<void> markVideoSeen(String videoId) async {
    final cached = feedVideoBox.get(videoId);
    if (cached != null) {
      cached.hasSeen = true;
      await cached.save();
    }
  }

  /// Optimistically increments likeCount for a cached video.
  Future<void> incrementLikeCount(String videoId) async {
    final cached = feedVideoBox.get(videoId);
    if (cached != null) {
      cached.likeCount++;
      await cached.save();
    }
  }

  // ── Member profile helpers ────────────────────────────────────────────────

  /// Returns the cached profile for [userId], or null if not cached.
  CachedMemberProfile? getCachedProfile(String userId) {
    return profileBox.get(userId);
  }

  /// Writes or updates a member profile in the cache.
  Future<void> cacheProfile(CachedMemberProfile profile) async {
    await profileBox.put(profile.userId, profile);
  }

  // ── Story helpers ─────────────────────────────────────────────────────────

  /// Returns non-expired cached stories ordered by createdAt descending.
  List<CachedStory> getCachedStories() {
    final list = storyBox.values.where((s) => !s.isExpired).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Returns non-expired cached stories ordered by createdAt descending.
  List<CachedStory> getValidStories() {
    final list = storyBox.values.where((s) => !s.isExpired).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Writes a batch of stories to the cache.
  Future<void> cacheStories(List<CachedStory> stories) async {
    for (final s in stories) {
      await storyBox.put(s.storyId, s);
    }
  }

  /// Marks a story as seen in the local cache.
  Future<void> markStorySeen(String storyId) async {
    final cached = storyBox.get(storyId);
    if (cached != null) {
      cached.isSeen = true;
      await cached.save();
    }
  }

  /// Removes a story from the cache by its ID.
  Future<void> deleteStoryFromCache(String storyId) async {
    await storyBox.delete(storyId);
  }

  /// Evicts all expired stories from the local cache (call on app start).
  Future<void> pruneExpiredStories() async {
    final expiredKeys = storyBox.values
        .where((s) => s.isExpired)
        .map((s) => s.storyId)
        .toList();
    await storyBox.deleteAll(expiredKeys);
  }
}
