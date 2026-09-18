import 'dart:convert';
import 'package:hive/hive.dart';

/// Hive TypeAdapter for offline member profile cache.
/// Hand-written (no build_runner needed). TypeId 11.
/// Cache TTL: 15 minutes (enforced by callers checking [isStale]).
class CachedMemberProfile extends HiveObject {
  String userId;
  String name;
  String? username;
  String? avatarUrl;
  String? bio;
  String? initials;
  int level;
  int currentXp;
  int xpToNextLevel;
  int streak;
  String archetypesJson;
  String badgesJson;
  DateTime cachedAt;

  CachedMemberProfile({
    required this.userId,
    required this.name,
    this.username,
    this.avatarUrl,
    this.bio,
    this.initials,
    this.level = 1,
    this.currentXp = 0,
    this.xpToNextLevel = 100,
    this.streak = 0,
    this.archetypesJson = '[]',
    this.badgesJson = '[]',
    required this.cachedAt,
  });

  List<String> get archetypes =>
      (jsonDecode(archetypesJson) as List).cast<String>();

  List<String> get badges =>
      (jsonDecode(badgesJson) as List).cast<String>();

  bool get isStale =>
      DateTime.now().difference(cachedAt).inMinutes > 15;

  factory CachedMemberProfile.fromSupabaseJson(Map<String, dynamic> json) {
    final rawName =
        (json['name'] ?? json['full_name'] ?? 'Explorer').toString();
    return CachedMemberProfile(
      userId: json['id'] as String,
      name: rawName,
      username: json['username'] as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      bio: json['bio'] as String?,
      initials: json['initials'] as String? ??
          (rawName.isNotEmpty ? rawName[0].toUpperCase() : 'Q'),
      level: (json['level'] as int?) ?? 1,
      currentXp: (json['currentXp'] as int?) ?? 0,
      xpToNextLevel: (json['xpToNextLevel'] as int?) ?? 100,
      streak: (json['streak'] as int?) ?? 0,
      archetypesJson: jsonEncode(json['archetypes'] ?? <String>[]),
      badgesJson: jsonEncode(json['badges'] ?? <String>[]),
      cachedAt: DateTime.now(),
    );
  }
}

class CachedMemberProfileAdapter extends TypeAdapter<CachedMemberProfile> {
  @override
  final int typeId = 11;

  @override
  CachedMemberProfile read(BinaryReader reader) {
    return CachedMemberProfile(
      userId: reader.readString(),
      name: reader.readString(),
      username: reader.readBool() ? reader.readString() : null,
      avatarUrl: reader.readBool() ? reader.readString() : null,
      bio: reader.readBool() ? reader.readString() : null,
      initials: reader.readBool() ? reader.readString() : null,
      level: reader.readInt(),
      currentXp: reader.readInt(),
      xpToNextLevel: reader.readInt(),
      streak: reader.readInt(),
      archetypesJson: reader.readString(),
      badgesJson: reader.readString(),
      cachedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, CachedMemberProfile obj) {
    writer.writeString(obj.userId);
    writer.writeString(obj.name);
    writer.writeBool(obj.username != null);
    if (obj.username != null) writer.writeString(obj.username!);
    writer.writeBool(obj.avatarUrl != null);
    if (obj.avatarUrl != null) writer.writeString(obj.avatarUrl!);
    writer.writeBool(obj.bio != null);
    if (obj.bio != null) writer.writeString(obj.bio!);
    writer.writeBool(obj.initials != null);
    if (obj.initials != null) writer.writeString(obj.initials!);
    writer.writeInt(obj.level);
    writer.writeInt(obj.currentXp);
    writer.writeInt(obj.xpToNextLevel);
    writer.writeInt(obj.streak);
    writer.writeString(obj.archetypesJson);
    writer.writeString(obj.badgesJson);
    writer.writeInt(obj.cachedAt.millisecondsSinceEpoch);
  }
}
