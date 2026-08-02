import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

class StoryItem {
  final String id;
  final String authorName;
  final String communityName;
  final String caption;
  final Color ringColor;
  final IconData icon;
  final bool isSeen;
  final String timeAgo;
  final String? authorAvatar;
  final String? title;
  final String? content;
  final List<Color>? gradient;
  final bool isSpoiler;

  const StoryItem({
    required this.id,
    required this.authorName,
    this.communityName = 'Community',
    this.caption = '',
    this.ringColor = AppColors.questBlue,
    this.icon = Icons.bolt,
    this.isSeen = false,
    required this.timeAgo,
    this.authorAvatar,
    this.title,
    this.content,
    this.gradient,
    this.isSpoiler = false,
  });

  StoryItem copyWith({
    String? id,
    String? authorName,
    String? communityName,
    String? caption,
    Color? ringColor,
    IconData? icon,
    bool? isSeen,
    String? timeAgo,
    String? authorAvatar,
    String? title,
    String? content,
    List<Color>? gradient,
    bool? isSpoiler,
  }) {
    return StoryItem(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      communityName: communityName ?? this.communityName,
      caption: caption ?? this.caption,
      ringColor: ringColor ?? this.ringColor,
      icon: icon ?? this.icon,
      isSeen: isSeen ?? this.isSeen,
      timeAgo: timeAgo ?? this.timeAgo,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      gradient: gradient ?? this.gradient,
      isSpoiler: isSpoiler ?? this.isSpoiler,
    );
  }
}

class StoriesNotifier extends Notifier<List<StoryItem>> {
  @override
  List<StoryItem> build() {
    return const [
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
  }

  void addStory(StoryItem newStory) {
    state = [newStory, ...state];
  }

  void markAsSeen(String storyId) {
    state = state.map((s) {
      if (s.id == storyId) {
        return s.copyWith(isSeen: true);
      }
      return s;
    }).toList();
  }
}

final storiesProvider = NotifierProvider<StoriesNotifier, List<StoryItem>>(() {
  return StoriesNotifier();
});
