class BeaconModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String creatorAvatar;
  final String title;
  final String description;
  final String hubId;
  final String hubName;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> attendeeIds;
  final List<String> attendeeAvatars;
  final int xpReward;
  final double angleRatio;
  final double radiusRatio;

  BeaconModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.creatorAvatar,
    required this.title,
    required this.description,
    required this.hubId,
    required this.hubName,
    required this.createdAt,
    required this.expiresAt,
    this.attendeeIds = const [],
    this.attendeeAvatars = const [],
    this.xpReward = 50,
    required this.angleRatio,
    required this.radiusRatio,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get attendeeCount => attendeeIds.length;

  Duration get remainingDuration {
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String get timeRemainingFormatted {
    final remaining = remainingDuration;
    if (remaining.inMinutes <= 0) return 'Expiring now';
    if (remaining.inHours >= 1) {
      final mins = remaining.inMinutes % 60;
      return '${remaining.inHours}h ${mins > 0 ? '${mins}m' : ''} left';
    }
    return '${remaining.inMinutes}m left';
  }

  bool isUserJoined(String userId) => attendeeIds.contains(userId);

  BeaconModel copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorAvatar,
    String? title,
    String? description,
    String? hubId,
    String? hubName,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? attendeeIds,
    List<String>? attendeeAvatars,
    int? xpReward,
    double? angleRatio,
    double? radiusRatio,
  }) {
    return BeaconModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      title: title ?? this.title,
      description: description ?? this.description,
      hubId: hubId ?? this.hubId,
      hubName: hubName ?? this.hubName,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      attendeeAvatars: attendeeAvatars ?? this.attendeeAvatars,
      xpReward: xpReward ?? this.xpReward,
      angleRatio: angleRatio ?? this.angleRatio,
      radiusRatio: radiusRatio ?? this.radiusRatio,
    );
  }

  factory BeaconModel.fromJson(Map<String, dynamic> json) {
    return BeaconModel(
      id: json['id'] as String,
      creatorId: json['creator_id'] as String? ?? json['creatorId'] as String? ?? '',
      creatorName: json['creator_name'] as String? ?? json['creatorName'] as String? ?? 'Anonymous',
      creatorAvatar: json['creator_avatar'] as String? ?? json['creatorAvatar'] as String? ?? '',
      title: json['title'] as String? ?? 'Meetup Beacon',
      description: json['description'] as String? ?? '',
      hubId: json['hub_id'] as String? ?? json['hubId'] as String? ?? '',
      hubName: json['hub_name'] as String? ?? json['hubName'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(hours: 2)),
      attendeeIds: (json['attendee_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['attendeeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      attendeeAvatars: (json['attendee_avatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          (json['attendeeAvatars'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      xpReward: json['xp_reward'] as int? ?? json['xpReward'] as int? ?? 50,
      angleRatio: (json['angle_ratio'] as num?)?.toDouble() ??
          (json['angleRatio'] as num?)?.toDouble() ??
          0.35,
      radiusRatio: (json['radius_ratio'] as num?)?.toDouble() ??
          (json['radiusRatio'] as num?)?.toDouble() ??
          0.55,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'creator_avatar': creatorAvatar,
      'title': title,
      'description': description,
      'hub_id': hubId,
      'hub_name': hubName,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'attendee_ids': attendeeIds,
      'attendee_avatars': attendeeAvatars,
      'xp_reward': xpReward,
      'angle_ratio': angleRatio,
      'radius_ratio': radiusRatio,
    };
  }
}
