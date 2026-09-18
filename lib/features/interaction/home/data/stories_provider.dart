import 'package:quest/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/utils/time_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'stories_repository.dart';

class StoryItem {
  final String id;
  final String authorName;
  final String communityName;
  final String caption;
  final Color ringColor;
  final IconData icon;
  final bool isSeen;
  final DateTime? createdAt;
  final String? authorAvatar;
  final String? title;
  final String? content;
  final List<Color>? gradient;
  final bool isSpoiler;
  final String? muxPlaybackId;
  final String? videoUrl;
  final bool isMe;
  final int viewsCount;

  StoryItem({
    required this.id,
    required this.authorName,
    this.communityName = 'Community',
    this.caption = '',
    this.ringColor = AppColors.questBlue,
    this.icon = Icons.bolt,
    this.isSeen = false,
    this.createdAt,
    this.authorAvatar,
    this.title,
    this.content,
    this.gradient,
    this.isSpoiler = false,
    this.muxPlaybackId,
    this.videoUrl,
    this.isMe = false,
    this.viewsCount = 0,
  });

  StoryItem copyWith({
    String? id,
    String? authorName,
    String? communityName,
    String? caption,
    Color? ringColor,
    IconData? icon,
    bool? isSeen,
    DateTime? createdAt,
    String? authorAvatar,
    String? title,
    String? content,
    List<Color>? gradient,
    bool? isSpoiler,
    String? muxPlaybackId,
    String? videoUrl,
    bool? isMe,
    int? viewsCount,
  }) {
    return StoryItem(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      communityName: communityName ?? this.communityName,
      caption: caption ?? this.caption,
      ringColor: ringColor ?? this.ringColor,
      icon: icon ?? this.icon,
      isSeen: isSeen ?? this.isSeen,
      createdAt: createdAt ?? this.createdAt,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      gradient: gradient ?? this.gradient,
      isSpoiler: isSpoiler ?? this.isSpoiler,
      muxPlaybackId: muxPlaybackId ?? this.muxPlaybackId,
      videoUrl: videoUrl ?? this.videoUrl,
      isMe: isMe ?? this.isMe,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    final rawPlaybackId = json['muxPlaybackId'] ?? json['mux_playback_id'];
    final rawAuthorName =
        json['authorName'] ?? json['author_name'] ?? 'Anonymous';
    final rawCommunity =
        json['communityName'] ?? json['community_name'] ?? 'Community';
    final rawAuthorAvatar =
        json['authorAvatar'] ?? json['author_avatar'] ?? json['avatar_url'];
    final rawContent = json['content'] ?? json['media_url'];
    final rawVideoUrl = json['videoUrl'] ?? json['video_url'];

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final storyUserId = json['user_id']?.toString();
    final bool isUserOwner =
        json['isMe'] as bool? ??
        json['is_me'] as bool? ??
        (storyUserId != null &&
            currentUserId != null &&
            storyUserId == currentUserId);

    return StoryItem(
      id: (json['id'] ?? 's_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      authorName: rawAuthorName.toString(),
      communityName: rawCommunity.toString(),
      caption: (json['caption'] ?? '').toString(),
      ringColor: Color(
        json['ringColor'] as int? ?? AppColors.questBlue.toARGB32(),
      ),
      icon: _getStoryIcon(json['icon'] as int?),
      isSeen: json['isSeen'] as bool? ?? json['is_seen'] as bool? ?? false,
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString())
          : null,
      authorAvatar: rawAuthorAvatar?.toString(),
      title: json['title'] as String?,
      content: rawContent?.toString(),
      gradient: (json['gradient'] as List<dynamic>?)
          ?.map((e) => Color(e as int))
          .toList(),
      isSpoiler: json['isSpoiler'] as bool? ?? false,
      muxPlaybackId: rawPlaybackId?.toString(),
      videoUrl: rawVideoUrl?.toString(),
      isMe: isUserOwner,
      viewsCount: (json['viewsCount'] ?? json['views_count'] as int?) ?? 0,
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
      'createdAt': createdAt?.toIso8601String(),
      'authorAvatar': authorAvatar,
      'title': title,
      'content': content,
      'gradient': gradient?.map((e) => e.toARGB32()).toList(),
      'isSpoiler': isSpoiler,
      'muxPlaybackId': muxPlaybackId,
      'videoUrl': videoUrl,
      'isMe': isMe,
      'viewsCount': viewsCount,
    };
  }

  Map<String, dynamic> toSupabase() {
    return {
      if (content != null || videoUrl != null) 'media_url': content ?? videoUrl,
      if (muxPlaybackId != null && muxPlaybackId!.isNotEmpty)
        'mux_playback_id': muxPlaybackId,
      'caption': caption,
      'authorName': authorName,
      'timeAgo': formattedTimeAgo,
      'isSeen': isSeen,
      if (authorAvatar != null && authorAvatar!.isNotEmpty)
        'authorAvatar': authorAvatar,
      if (communityName.isNotEmpty) 'communityName': communityName,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  String get formattedTimeAgo => TimeUtils.formatStoryTime(createdAt);
}

class StoriesNotifier extends AsyncNotifier<List<StoryItem>> {
  late final StoriesRepository _repository;

  @override
  Future<List<StoryItem>> build() async {
    _repository = ref.watch(storiesRepositoryProvider);
    return _repository.getStories();
  }

  Future<void> addStory(StoryItem newStory) async {
    addStoryLocally(newStory);

    try {
      await _repository.addStory(newStory);
    } catch (err) {
      debugPrint('[StoriesNotifier] addStory persistence notice: $err');
    }
  }

  void addStoryLocally(StoryItem newStory) {
    final currentList = state.value ?? [];
    // Optimistically update Riverpod state immediately
    state = AsyncData([
      newStory,
      ...currentList.where((s) => s.id != newStory.id),
    ]);
  }

  Future<void> deleteStory(String storyId) async {
    final currentList = state.value ?? [];
    state = AsyncData(currentList.where((s) => s.id != storyId).toList());

    try {
      await _repository.deleteStory(storyId);
    } catch (err) {
      debugPrint('[StoriesNotifier] deleteStory notice: $err');
    }
  }

  Future<void> markAsSeen(String storyId) async {
    if (state.value == null) return;

    state = AsyncData(
      state.value!.map((s) {
        if (s.id == storyId) {
          return s.copyWith(isSeen: true);
        }
        return s;
      }).toList(),
    );

    try {
      await _repository.markAsSeen(storyId);
    } catch (_) {}
  }
}

final storiesProvider = AsyncNotifierProvider<StoriesNotifier, List<StoryItem>>(
  () {
    return StoriesNotifier();
  },
);
