import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import 'stories_provider.dart';

abstract class StoriesRepository {
  Future<List<StoryItem>> getStories();
  Future<StoryItem> addStory(StoryItem story);
  Future<void> markAsSeen(String storyId);
}

class MockStoriesRepository implements StoriesRepository {
  final List<StoryItem> _stories = const [
    StoryItem(
      id: 's1',
      authorName: 'Sarah C.',
      communityName: 'Startup Founders',
      caption: 'Live demo from the downtown venue! The turnout tonight is incredible.',
      ringColor: AppColors.emerald,
      icon: Icons.rocket_launch,
      isSeen: false,
      timeAgo: '12m ago',
    ),
    StoryItem(
      id: 's2',
      authorName: 'Marcus T.',
      communityName: 'Flutter Builders',
      caption: 'Benchmark tests are in: 120 FPS buttery smooth state transitions.',
      ringColor: AppColors.questBlue,
      icon: Icons.flutter_dash,
      isSeen: false,
      timeAgo: '45m ago',
    ),
    StoryItem(
      id: 's3',
      authorName: 'Elena V.',
      communityName: 'Design Systems NYC',
      caption: 'Testing the new fluid typography scale and dark contrast modes.',
      ringColor: AppColors.auroraPurple,
      icon: Icons.palette,
      isSeen: false,
      timeAgo: '2h ago',
    ),
    StoryItem(
      id: 's4',
      authorName: 'David K.',
      communityName: 'City Photographers',
      caption: 'Golden hour at Central Park bridge. Perfect light for street portraits.',
      ringColor: AppColors.crimson,
      icon: Icons.camera_alt,
      isSeen: true,
      timeAgo: '4h ago',
    ),
  ];

  @override
  Future<List<StoryItem>> getStories() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_stories);
  }

  @override
  Future<StoryItem> addStory(StoryItem story) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return story;
  }

  @override
  Future<void> markAsSeen(String storyId) async {
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

class SupabaseStoriesRepository implements StoriesRepository {
  final SupabaseClient _client;

  SupabaseStoriesRepository(this._client);

  @override
  Future<List<StoryItem>> getStories() async {
    final data = await _client.from('stories').select();
    return data.map((json) => StoryItem.fromJson(json)).toList();
  }

  @override
  Future<StoryItem> addStory(StoryItem story) async {
    final data = await _client.from('stories').insert(story.toJson()).select().single();
    return StoryItem.fromJson(data);
  }

  @override
  Future<void> markAsSeen(String storyId) async {
    await _client.from('stories').update({'isSeen': true}).eq('id', storyId);
  }
}

final storiesRepositoryProvider = Provider<StoriesRepository>((ref) {
  return SupabaseStoriesRepository(Supabase.instance.client);
});
