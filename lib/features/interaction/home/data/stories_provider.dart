import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stories_repository.dart';

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

  StoryItem({
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

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] as String,
      authorName: json['authorName'] as String,
      communityName: json['communityName'] as String? ?? 'Community',
      caption: json['caption'] as String? ?? '',
      ringColor: Color(
        json['ringColor'] as int? ?? AppColors.questBlue.toARGB32(),
      ),
      icon: _getStoryIcon(json['icon'] as int?),
      isSeen: json['isSeen'] as bool? ?? false,
      timeAgo: json['timeAgo'] as String,
      authorAvatar: json['authorAvatar'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      gradient: (json['gradient'] as List<dynamic>?)
          ?.map((e) => Color(e as int))
          .toList(),
      isSpoiler: json['isSpoiler'] as bool? ?? false,
    );
  }

  static IconData _getStoryIcon(int? codePoint) {
    if (codePoint == Icons.code.codePoint) return Icons.code;
    if (codePoint == Icons.rocket_launch.codePoint) return Icons.rocket_launch;
    if (codePoint == Icons.architecture.codePoint) return Icons.architecture;
    if (codePoint == Icons.brush.codePoint) return Icons.brush;
    return Icons.history;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'communityName': communityName,
      'caption': caption,
      'ringColor': ringColor.toARGB32(),
      'icon': icon.codePoint,
      'isSeen': isSeen,
      'timeAgo': timeAgo,
      'authorAvatar': authorAvatar,
      'title': title,
      'content': content,
      'gradient': gradient?.map((e) => e.toARGB32()).toList(),
      'isSpoiler': isSpoiler,
    };
  }
}

class StoriesNotifier extends AsyncNotifier<List<StoryItem>> {
  late final StoriesRepository _repository;

  @override
  Future<List<StoryItem>> build() async {
    _repository = ref.watch(storiesRepositoryProvider);
    return _repository.getStories();
  }

  Future<void> addStory(StoryItem newStory) async {
    if (state.value == null) return;

    final addedStory = await _repository.addStory(newStory);
    state = AsyncData([addedStory, ...state.value!]);
  }

  Future<void> markAsSeen(String storyId) async {
    if (state.value == null) return;

    await _repository.markAsSeen(storyId);

    state = AsyncData(
      state.value!.map((s) {
        if (s.id == storyId) {
          return s.copyWith(isSeen: true);
        }
        return s;
      }).toList(),
    );
  }
}

final storiesProvider = AsyncNotifierProvider<StoriesNotifier, List<StoryItem>>(
  () {
    return StoriesNotifier();
  },
);
