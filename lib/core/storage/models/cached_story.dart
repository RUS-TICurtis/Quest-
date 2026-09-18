import 'package:hive/hive.dart';

/// Hive TypeAdapter for offline story cache.
/// Hand-written (no build_runner needed). TypeId 12.
/// Mirrors the `stories` table's 24-hour TTL enforced by the server pg_cron job.
///
/// Column name reference — stories table uses camelCase quoted identifiers:
///   "authorName", "communityName", "isSeen", "createdAt", "authorAvatar"
///   media_url, mux_playback_id, user_id (snake_case — added in 20260826 migration)
class CachedStory extends HiveObject {
  String storyId;
  String authorName;
  String? communityName;
  String? caption;
  String? authorAvatar;
  String? mediaUrl;
  String? muxPlaybackId;
  String? userId;
  bool isSeen;
  DateTime createdAt;
  DateTime expiresAt;
  DateTime cachedAt;

  CachedStory({
    required this.storyId,
    required this.authorName,
    this.communityName,
    this.caption,
    this.authorAvatar,
    this.mediaUrl,
    this.muxPlaybackId,
    this.userId,
    this.isSeen = false,
    required this.createdAt,
    required this.expiresAt,
    required this.cachedAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory CachedStory.fromSupabaseJson(Map<String, dynamic> json) {
    // Stories table uses camelCase "createdAt" but may have snake_case fallback
    final created = json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
        : json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now();

    return CachedStory(
      storyId: (json['id'] as String? ?? ''),
      authorName: (json['authorName'] as String? ?? 'Unknown'),
      communityName: json['communityName'] as String?,
      caption: json['caption'] as String?,
      authorAvatar: json['authorAvatar'] as String?,
      mediaUrl: json['media_url'] as String?,
      muxPlaybackId: json['mux_playback_id'] as String?,
      userId: json['user_id'] as String?,
      isSeen: (json['isSeen'] as bool?) ?? false,
      createdAt: created,
      expiresAt: created.add(const Duration(hours: 24)),
      cachedAt: DateTime.now(),
    );
  }
}

class CachedStoryAdapter extends TypeAdapter<CachedStory> {
  @override
  final int typeId = 12;

  @override
  CachedStory read(BinaryReader reader) {
    return CachedStory(
      storyId: reader.readString(),
      authorName: reader.readString(),
      communityName: reader.readBool() ? reader.readString() : null,
      caption: reader.readBool() ? reader.readString() : null,
      authorAvatar: reader.readBool() ? reader.readString() : null,
      mediaUrl: reader.readBool() ? reader.readString() : null,
      muxPlaybackId: reader.readBool() ? reader.readString() : null,
      userId: reader.readBool() ? reader.readString() : null,
      isSeen: reader.readBool(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, CachedStory obj) {
    writer.writeString(obj.storyId);
    writer.writeString(obj.authorName);
    writer.writeBool(obj.communityName != null);
    if (obj.communityName != null) writer.writeString(obj.communityName!);
    writer.writeBool(obj.caption != null);
    if (obj.caption != null) writer.writeString(obj.caption!);
    writer.writeBool(obj.authorAvatar != null);
    if (obj.authorAvatar != null) writer.writeString(obj.authorAvatar!);
    writer.writeBool(obj.mediaUrl != null);
    if (obj.mediaUrl != null) writer.writeString(obj.mediaUrl!);
    writer.writeBool(obj.muxPlaybackId != null);
    if (obj.muxPlaybackId != null) writer.writeString(obj.muxPlaybackId!);
    writer.writeBool(obj.userId != null);
    if (obj.userId != null) writer.writeString(obj.userId!);
    writer.writeBool(obj.isSeen);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
    writer.writeInt(obj.expiresAt.millisecondsSinceEpoch);
    writer.writeInt(obj.cachedAt.millisecondsSinceEpoch);
  }
}
