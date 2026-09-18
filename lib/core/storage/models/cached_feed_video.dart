import 'package:hive/hive.dart';

/// Hive TypeAdapter for offline feed video cache.
/// Hand-written (no build_runner needed). TypeId 10.
/// Used for stale-while-revalidate display and seen-video deduplication.
class CachedFeedVideo extends HiveObject {
  String videoId;
  String videoUrl;
  String? thumbnailUrl;
  String? title;
  String? description;
  int viewCount;
  int likeCount;
  int commentCount;
  int shareCount;
  String? creatorUsername;
  String? creatorAvatarUrl;
  String? creatorId;
  double engagementScore;
  int durationSeconds;
  DateTime cachedAt;
  bool hasSeen;

  CachedFeedVideo({
    required this.videoId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.title,
    this.description,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.creatorUsername,
    this.creatorAvatarUrl,
    this.creatorId,
    this.engagementScore = 0.0,
    this.durationSeconds = 0,
    required this.cachedAt,
    this.hasSeen = false,
  });

  factory CachedFeedVideo.fromJson(Map<String, dynamic> v) {
    final profile = v['profiles'] as Map<String, dynamic>? ?? {};
    return CachedFeedVideo(
      videoId: (v['id'] as String? ?? ''),
      videoUrl: (v['video_url'] as String? ?? ''),
      thumbnailUrl: v['thumbnail_url'] as String?,
      title: v['title'] as String?,
      description: v['description'] as String?,
      viewCount: (v['view_count'] as int?) ?? 0,
      likeCount: (v['like_count'] as int?) ?? 0,
      commentCount: (v['comment_count'] as int?) ?? 0,
      shareCount: (v['share_count'] as int?) ?? 0,
      creatorId: (v['creator_id'] as String?) ?? (v['user_id'] as String?),
      creatorUsername: (v['creator_username'] as String?) ??
          (profile['username'] as String?),
      creatorAvatarUrl: (v['creator_avatar_url'] as String?) ??
          (profile['avatar_url'] as String?),
      engagementScore: ((v['engagement_score'] ?? 0) as num).toDouble(),
      durationSeconds: (v['duration_seconds'] as int?) ?? 0,
      cachedAt: DateTime.now(),
    );
  }
}

class CachedFeedVideoAdapter extends TypeAdapter<CachedFeedVideo> {
  @override
  final int typeId = 10;

  @override
  CachedFeedVideo read(BinaryReader reader) {
    return CachedFeedVideo(
      videoId: reader.readString(),
      videoUrl: reader.readString(),
      thumbnailUrl: reader.readBool() ? reader.readString() : null,
      title: reader.readBool() ? reader.readString() : null,
      description: reader.readBool() ? reader.readString() : null,
      viewCount: reader.readInt(),
      likeCount: reader.readInt(),
      commentCount: reader.readInt(),
      shareCount: reader.readInt(),
      creatorUsername: reader.readBool() ? reader.readString() : null,
      creatorAvatarUrl: reader.readBool() ? reader.readString() : null,
      creatorId: reader.readBool() ? reader.readString() : null,
      engagementScore: reader.readDouble(),
      durationSeconds: reader.readInt(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      hasSeen: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, CachedFeedVideo obj) {
    writer.writeString(obj.videoId);
    writer.writeString(obj.videoUrl);
    writer.writeBool(obj.thumbnailUrl != null);
    if (obj.thumbnailUrl != null) writer.writeString(obj.thumbnailUrl!);
    writer.writeBool(obj.title != null);
    if (obj.title != null) writer.writeString(obj.title!);
    writer.writeBool(obj.description != null);
    if (obj.description != null) writer.writeString(obj.description!);
    writer.writeInt(obj.viewCount);
    writer.writeInt(obj.likeCount);
    writer.writeInt(obj.commentCount);
    writer.writeInt(obj.shareCount);
    writer.writeBool(obj.creatorUsername != null);
    if (obj.creatorUsername != null) writer.writeString(obj.creatorUsername!);
    writer.writeBool(obj.creatorAvatarUrl != null);
    if (obj.creatorAvatarUrl != null) writer.writeString(obj.creatorAvatarUrl!);
    writer.writeBool(obj.creatorId != null);
    if (obj.creatorId != null) writer.writeString(obj.creatorId!);
    writer.writeDouble(obj.engagementScore);
    writer.writeInt(obj.durationSeconds);
    writer.writeInt(obj.cachedAt.millisecondsSinceEpoch);
    writer.writeBool(obj.hasSeen);
  }
}
