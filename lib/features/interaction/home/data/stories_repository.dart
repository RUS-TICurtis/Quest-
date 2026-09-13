import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stories_provider.dart';

abstract class StoriesRepository {
  Future<List<StoryItem>> getStories();
  Future<StoryItem> addStory(StoryItem story);
  Future<void> deleteStory(String storyId);
  Future<void> markAsSeen(String storyId);
}

final List<StoryItem> defaultSeedStories = [
  StoryItem(
    id: 's1',
    authorName: 'Sarah C.',
    communityName: 'Startup Founders',
    caption:
        'Live demo from the downtown venue! The turnout tonight is incredible.',
    ringColor: AppColors.emerald,
    icon: Icons.rocket_launch,
    isSeen: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
  ),
  StoryItem(
    id: 's2',
    authorName: 'Marcus T.',
    communityName: 'Flutter Builders',
    caption:
        'Benchmark tests are in: 120 FPS buttery smooth state transitions.',
    ringColor: AppColors.questBlue,
    icon: Icons.flutter_dash,
    isSeen: false,
    createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
  ),
  StoryItem(
    id: 's3',
    authorName: 'Elena V.',
    communityName: 'Design Systems NYC',
    caption:
        'Testing the new fluid typography scale and dark contrast modes.',
    ringColor: AppColors.auroraPurple,
    icon: Icons.palette,
    isSeen: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  StoryItem(
    id: 's4',
    authorName: 'David K.',
    communityName: 'City Photographers',
    caption:
        'Golden hour at Central Park bridge. Perfect light for street portraits.',
    ringColor: AppColors.crimson,
    icon: Icons.camera_alt,
    isSeen: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
  ),
];

class MockStoriesRepository implements StoriesRepository {
  final List<StoryItem> _stories = List.from(defaultSeedStories);

  @override
  Future<List<StoryItem>> getStories() async {
    await Future.delayed(Duration(milliseconds: 150));
    return List.from(_stories);
  }

  @override
  Future<StoryItem> addStory(StoryItem story) async {
    await Future.delayed(Duration(milliseconds: 100));
    _stories.removeWhere((s) => s.id == story.id);
    _stories.insert(0, story);
    return story;
  }

  @override
  Future<void> deleteStory(String storyId) async {
    await Future.delayed(Duration(milliseconds: 50));
    _stories.removeWhere((s) => s.id == storyId);
  }

  @override
  Future<void> markAsSeen(String storyId) async {
    await Future.delayed(Duration(milliseconds: 50));
    final idx = _stories.indexWhere((s) => s.id == storyId);
    if (idx != -1) {
      _stories[idx] = _stories[idx].copyWith(isSeen: true);
    }
  }
}

class SupabaseStoriesRepository implements StoriesRepository {
  final SupabaseClient _client;
  final List<StoryItem> _localStories = List.from(defaultSeedStories);

  SupabaseStoriesRepository(this._client);

  @override
  Future<List<StoryItem>> getStories() async {
    try {
      final data = await _client
          .from('stories')
          .select()
          .order('createdAt', ascending: false);

      if (data.isNotEmpty) {
        final remote = data.map((json) => StoryItem.fromJson(json)).toList();
        // Clear local seed mock stories and populate with real stories from Supabase
        _localStories.clear();
        _localStories.addAll(remote);
      }
    } catch (e) {
      debugPrint('[SupabaseStoriesRepository] getStories notice: $e');
    }
    return List.from(_localStories);
  }

  @override
  Future<StoryItem> addStory(StoryItem story) async {
    _localStories.removeWhere((s) => s.id == story.id);
    _localStories.insert(0, story);

    try {
      final payload = story.toSupabase();
      if (_client.auth.currentUser != null) {
        payload['user_id'] = _client.auth.currentUser!.id;
      }
      final res = await _client.from('stories').insert(payload).select().single();
      final created = StoryItem.fromJson(res);
      final idx = _localStories.indexWhere((s) => s.id == story.id);
      if (idx != -1) {
        _localStories[idx] = created;
      }
      return created;
    } catch (e) {
      debugPrint('[SupabaseStoriesRepository] addStory fallback notice: $e');
      return story;
    }
  }

  @override
  Future<void> deleteStory(String storyId) async {
    _localStories.removeWhere((s) => s.id == storyId);
    if (!storyId.startsWith('s_') && !storyId.startsWith('s')) {
      try {
        await _client.from('stories').delete().eq('id', storyId);
      } catch (e) {
        debugPrint('[SupabaseStoriesRepository] deleteStory fallback notice: $e');
      }
    }
  }

  @override
  Future<void> markAsSeen(String storyId) async {
    final idx = _localStories.indexWhere((s) => s.id == storyId);
    if (idx != -1) {
      _localStories[idx] = _localStories[idx].copyWith(isSeen: true);
    }
    // Only update Supabase for real persisted database records
    if (!storyId.startsWith('s_') && !storyId.startsWith('s')) {
      try {
        await _client.from('stories').update({'isSeen': true}).eq('id', storyId);
      } catch (_) {}
    }
  }
}

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return SupabaseStoriesRepository(Supabase.instance.client);
});
