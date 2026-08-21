class CreatorVideo {
  final String id;
  final String creatorId;
  final String videoUrl;
  final String thumbnailUrl;
  final String title;
  final String description;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;
  final double engagementScore;
  final bool isLiked;

  // Video metadata
  final int durationSeconds;
  final String? muxPlaybackId;
  final String? muxStatus;
  
  // Creator Info
  final String? creatorUsername;
  final String? creatorAvatarUrl;

  CreatorVideo({
    required this.id,
    required this.creatorId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.title,
    required this.description,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.createdAt,
    required this.engagementScore,
    this.isLiked = false,
    required this.durationSeconds,
    this.muxPlaybackId,
    this.muxStatus,
    this.creatorUsername,
    this.creatorAvatarUrl,
  });

  factory CreatorVideo.fromJson(Map<String, dynamic> json) {
    return CreatorVideo(
      id: json['id'] as String? ?? '',
      creatorId: json['creator_id'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      viewCount: json['view_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      shareCount: json['share_count'] as int? ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      engagementScore: (json['engagement_score'] as num?)?.toDouble() ?? 0.0,
      isLiked: json['is_liked'] as bool? ?? false,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      muxPlaybackId: json['mux_playback_id'] as String?,
      muxStatus: json['mux_status'] as String?,
      creatorUsername: json['creator_username'] as String?,
      creatorAvatarUrl: json['creator_avatar_url'] as String?,
    );
  }
}
