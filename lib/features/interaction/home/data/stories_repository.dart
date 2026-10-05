import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/core/storage/local_database_service.dart';
import 'package:quest/core/storage/models/cached_story.dart';
import 'stories_provider.dart';

abstract class StoriesRepository {
  Future<List<StoryItem>> getStories();
  Future<StoryItem> addStory(StoryItem story);
  Future<void> deleteStory(String storyId);
  Future<void> markAsSeen(String storyId);
}

class MockStoriesRepository implements StoriesRepository {
  final List<StoryItem> _stories = [];

  @override
  Future<List<StoryItem>> getStories() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return List.from(_stories);
  }

  @override
  Future<StoryItem> addStory(StoryItem story) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _stories.removeWhere((s) => s.id == story.id);
    _stories.insert(0, story);
    return story;
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _stories.removeWhere((s) => s.id == storyId);
  }

  @override
  Future<void> markAsSeen(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final idx = _stories.indexWhere((s) => s.id == storyId);
    if (idx != -1) {
      _stories[idx] = _stories[idx].copyWith(isSeen: true);
    }
  }
}

class SupabaseStoriesRepository implements StoriesRepository {
  final SupabaseClient _client;
  final LocalDatabaseService _localDb;

  SupabaseStoriesRepository(this._client, this._localDb);

  @override
  Future<List<StoryItem>> getStories() async {
    // 1. Instant cache hit from Hive
    final cached = _localDb.getValidStories();
    final localStories = cached.map((c) => StoryItem(
      id: c.storyId,
      authorName: c.authorName,
      communityName: c.communityName ?? 'Community',
      caption: c.caption ?? '',
      authorAvatar: c.authorAvatar,
      isSeen: c.isSeen,
      createdAt: c.createdAt,
      content: c.mediaUrl,
      videoUrl: c.mediaUrl,
      muxPlaybackId: c.muxPlaybackId,
      isMe: _client.auth.currentUser?.id == c.userId,
    )).toList();

    // 2. Background refresh
    try {
      final data = await _client
          .from('stories')
          .select()
          .order('createdAt', ascending: false);

      if (data.isNotEmpty) {
        final now = DateTime.now();
        final remote = data
            .map((json) => StoryItem.fromJson(json))
            .where(
              (story) =>
                  story.createdAt == null ||
                  now.difference(story.createdAt!).inHours < 24,
            )
            .toList();
        
        final cachedStories = remote.map((s) => CachedStory(
          storyId: s.id,
          authorName: s.authorName,
          communityName: s.communityName,
          caption: s.caption,
          authorAvatar: s.authorAvatar,
          mediaUrl: s.content ?? s.videoUrl,
          muxPlaybackId: s.muxPlaybackId,
          userId: s.isMe ? _client.auth.currentUser?.id : null,
          isSeen: s.isSeen,
          createdAt: s.createdAt ?? DateTime.now(),
          expiresAt: (s.createdAt ?? DateTime.now()).add(const Duration(hours: 24)),
          cachedAt: DateTime.now(),
        )).toList();
        
        await _localDb.cacheStories(cachedStories);
        return remote;
      }
    } catch (e) {
      debugPrint('[SupabaseStoriesRepository] getStories notice: $e');
    }
    return localStories;
  }

  @override
  Future<StoryItem> addStory(StoryItem story) async {
    try {
      final payload = story.toSupabase();
      if (_client.auth.currentUser != null) {
        payload['user_id'] = _client.auth.currentUser!.id;
      }
      final res = await _client
          .from('stories')
          .insert(payload)
          .select()
          .single();
      final created = StoryItem.fromJson(res);
      
      final cStory = CachedStory(
        storyId: created.id,
        authorName: created.authorName,
        communityName: created.communityName,
        caption: created.caption,
        authorAvatar: created.authorAvatar,
        mediaUrl: created.content ?? created.videoUrl,
        muxPlaybackId: created.muxPlaybackId,
        userId: _client.auth.currentUser?.id,
        isSeen: created.isSeen,
        createdAt: created.createdAt ?? DateTime.now(),
        expiresAt: (created.createdAt ?? DateTime.now()).add(const Duration(hours: 24)),
        cachedAt: DateTime.now(),
      );
      await _localDb.cacheStories([cStory]);

      return created;
    } catch (e) {
      debugPrint('[SupabaseStoriesRepository] addStory fallback notice: $e');
      return story;
    }
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await _localDb.deleteStoryFromCache(storyId);
    if (!storyId.startsWith('s_') && !storyId.startsWith('s')) {
      try {
        await _client.functions.invoke(
          'delete-experience',
          body: {'id': storyId},
        );
      } catch (e) {
        try {
          await _client.from('stories').delete().eq('id', storyId);
        } catch (innerErr) {
          debugPrint(
            '[SupabaseStoriesRepository] deleteStory fallback notice: $innerErr',
          );
        }
      }
    }
  }

  @override
  Future<void> markAsSeen(String storyId) async {
    await _localDb.markStorySeen(storyId);
    if (!storyId.startsWith('s_') && !storyId.startsWith('s')) {
      try {
        await _client
            .from('stories')
            .update({'isSeen': true})
            .eq('id', storyId);
      } catch (_) {}
    }
  }
}

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  final localDb = ref.watch(localDatabaseProvider);
  return SupabaseStoriesRepository(Supabase.instance.client, localDb);
});
