import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/audio/stage_audio_service.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'stage_repository.dart';

class StageSpeaker {
  final String id;
  final String name;
  final String role;
  final String avatar;
  final bool isMuted;
  final bool isSpeaking;
  final String archetype;

  StageSpeaker({
    required this.id,
    required this.name,
    required this.role,
    required this.avatar,
    this.isMuted = false,
    this.isSpeaking = false,
    this.archetype = 'Builder',
  });

  StageSpeaker copyWith({
    String? id,
    String? name,
    String? role,
    String? avatar,
    bool? isMuted,
    bool? isSpeaking,
    String? archetype,
  }) {
    return StageSpeaker(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      isMuted: isMuted ?? this.isMuted,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      archetype: archetype ?? this.archetype,
    );
  }

  factory StageSpeaker.fromJson(Map<String, dynamic> json) {
    return StageSpeaker(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      avatar: json['avatar'] as String,
      isMuted: json['isMuted'] as bool? ?? false,
      isSpeaking: json['isSpeaking'] as bool? ?? false,
      archetype: json['archetype'] as String? ?? 'Builder',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar': avatar,
      'isMuted': isMuted,
      'isSpeaking': isSpeaking,
      'archetype': archetype,
    };
  }
}

class StageParticipant {
  final String id;
  final String name;
  final String avatar;
  final bool hasHandRaised;

  StageParticipant({
    required this.id,
    required this.name,
    required this.avatar,
    this.hasHandRaised = false,
  });

  StageParticipant copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? hasHandRaised,
  }) {
    return StageParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      hasHandRaised: hasHandRaised ?? this.hasHandRaised,
    );
  }

  factory StageParticipant.fromJson(Map<String, dynamic> json) {
    return StageParticipant(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      hasHandRaised: json['hasHandRaised'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'hasHandRaised': hasHandRaised,
    };
  }
}

class StageReaction {
  final String id;
  final String emoji;
  final double xOffset;

  StageReaction({required this.id, required this.emoji, required this.xOffset});

  factory StageReaction.fromJson(Map<String, dynamic> json) {
    return StageReaction(
      id: json['id'] as String,
      emoji: json['emoji'] as String,
      xOffset: (json['xOffset'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'emoji': emoji, 'xOffset': xOffset};
  }
}

class StageState {
  final String stageId;
  final String title;
  final String topic;
  final String communityName;
  final bool isMicMuted;
  final bool isHandRaised;
  final List<StageSpeaker> speakers;
  final List<StageParticipant> audience;
  final List<StageReaction> activeReactions;

  StageState({
    required this.stageId,
    required this.title,
    required this.topic,
    required this.communityName,
    this.isMicMuted = true,
    this.isHandRaised = false,
    required this.speakers,
    required this.audience,
    this.activeReactions = const [],
  });

  StageState copyWith({
    String? stageId,
    String? title,
    String? topic,
    String? communityName,
    bool? isMicMuted,
    bool? isHandRaised,
    List<StageSpeaker>? speakers,
    List<StageParticipant>? audience,
    List<StageReaction>? activeReactions,
  }) {
    return StageState(
      stageId: stageId ?? this.stageId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      communityName: communityName ?? this.communityName,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      speakers: speakers ?? this.speakers,
      audience: audience ?? this.audience,
      activeReactions: activeReactions ?? this.activeReactions,
    );
  }

  factory StageState.fromJson(Map<String, dynamic> json) {
    return StageState(
      stageId: json['stageId'] as String,
      title: json['title'] as String,
      topic: json['topic'] as String,
      communityName: json['communityName'] as String,
      isMicMuted: json['isMicMuted'] as bool? ?? true,
      isHandRaised: json['isHandRaised'] as bool? ?? false,
      speakers:
          (json['speakers'] as List<dynamic>?)
              ?.map((e) => StageSpeaker.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      audience:
          (json['audience'] as List<dynamic>?)
              ?.map((e) => StageParticipant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeReactions:
          (json['activeReactions'] as List<dynamic>?)
              ?.map((e) => StageReaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'title': title,
      'topic': topic,
      'communityName': communityName,
      'isMicMuted': isMicMuted,
      'isHandRaised': isHandRaised,
      'speakers': speakers.map((e) => e.toJson()).toList(),
      'audience': audience.map((e) => e.toJson()).toList(),
      'activeReactions': activeReactions.map((e) => e.toJson()).toList(),
    };
  }
}

/// Parameterized by [stageId] via constructor injection (Riverpod 3.x pattern).
/// Each unique [stageId] gets its own isolated notifier instance.
class StageNotifier extends AsyncNotifier<StageState> {
  /// The stage to load. Set at construction time for family provider usage.
  final String stageId;

  StageNotifier(this.stageId);

  /// Tracks reaction cleanup timers so we can cancel on disposal.
  final List<Timer> _reactionTimers = [];

  late StageRepository _repository;
  late StageAudioService _audioService;
  StreamSubscription<Map<String, double>>? _volumeSubscription;

  @override
  Future<StageState> build() async {
    _repository = ref.watch(stageRepositoryProvider);
    _audioService = ref.watch(stageAudioServiceProvider);

    final channel = _repository.subscribeToStage(
      stageId,
      onReaction: (emoji, xOffset) {
        _handleIncomingReaction(emoji, xOffset);
      },
      onHandRaise: (userId, userName, userAvatar, hasRaised) {
        _handleIncomingHandRaise(userId, userName, userAvatar, hasRaised);
      },
      onSpeakerPromotion: (participantId, name, avatar) {
        _handleIncomingSpeakerPromotion(participantId, name, avatar);
      },
    );

    final details = await _repository.getStageDetails(stageId);
    final user = ref.read(authProvider).user;
    final isSpeaker = user != null && details.speakers.any((s) => s.id == user.id);

    unawaited(
      _audioService.joinStage(
        stageId: stageId,
        userId: user?.id ?? 'guest_${DateTime.now().millisecondsSinceEpoch}',
        isSpeaker: isSpeaker,
      ),
    );

    _volumeSubscription = _audioService.speakerVolumeLevelsStream.listen((volumes) {
      if (state.value == null || volumes.isEmpty) return;
      final currentSpeakers = state.value!.speakers;
      bool hasChanges = false;
      final updatedSpeakers = currentSpeakers.map((s) {
        final vol = volumes[s.id] ?? 0.0;
        final isSpeakingNow = vol > 0.05;
        if (s.isSpeaking != isSpeakingNow) {
          hasChanges = true;
          return s.copyWith(isSpeaking: isSpeakingNow);
        }
        return s;
      }).toList();

      if (hasChanges) {
        state = AsyncData(state.value!.copyWith(speakers: updatedSpeakers));
      }
    });

    // Cancel all pending reaction timers, audio streaming, and unsubscribe from channel on dispose.
    ref.onDispose(() {
      _volumeSubscription?.cancel();
      _audioService.leaveStage();
      _repository.unsubscribeFromStage(channel);
      for (final t in _reactionTimers) {
        t.cancel();
      }
      _reactionTimers.clear();
    });

    return details;
  }

  void _handleIncomingReaction(String emoji, double xOffset) {
    if (state.value == null) return;
    final reaction = StageReaction(
      id: 'rt_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      emoji: emoji,
      xOffset: xOffset,
    );

    state = AsyncData(
      state.value!.copyWith(
        activeReactions: [...state.value!.activeReactions, reaction],
      ),
    );

    final timer = Timer(const Duration(seconds: 2), () {
      if (state.value != null) {
        state = AsyncData(
          state.value!.copyWith(
            activeReactions: state.value!.activeReactions
                .where((r) => r.id != reaction.id)
                .toList(),
          ),
        );
      }
    });
    _reactionTimers.add(timer);
  }

  void _handleIncomingHandRaise(
    String userId,
    String userName,
    String userAvatar,
    bool hasRaised,
  ) {
    if (state.value == null) return;
    final current = state.value!;
    final index = current.audience.indexWhere((p) => p.id == userId);

    List<StageParticipant> updatedAudience;
    if (index != -1) {
      updatedAudience = current.audience.map((p) {
        if (p.id == userId) {
          return p.copyWith(hasHandRaised: hasRaised);
        }
        return p;
      }).toList();
    } else {
      updatedAudience = [
        ...current.audience,
        StageParticipant(
          id: userId,
          name: userName,
          avatar: userAvatar,
          hasHandRaised: hasRaised,
        ),
      ];
    }

    state = AsyncData(current.copyWith(audience: updatedAudience));
  }

  void _handleIncomingSpeakerPromotion(
    String participantId,
    String name,
    String avatar,
  ) {
    if (state.value == null) return;
    final current = state.value!;
    final updatedAudience =
        current.audience.where((p) => p.id != participantId).toList();

    final currentUserId = ref.read(authProvider).user?.id;
    if (participantId == currentUserId) {
      _audioService.setSpeakerRole(true);
    }

    if (!current.speakers.any((s) => s.id == participantId)) {
      final newSpeaker = StageSpeaker(
        id: participantId,
        name: name,
        role: 'Speaker • Invited',
        avatar: avatar,
        isMuted: false,
        isSpeaking: false,
        archetype: 'Seeker',
      );

      state = AsyncData(
        current.copyWith(
          audience: updatedAudience,
          speakers: [...current.speakers, newSpeaker],
        ),
      );
    }
  }

  void toggleMic() {
    if (state.value != null) {
      final newMicMuted = !state.value!.isMicMuted;
      _audioService.setMicrophoneMuted(newMicMuted);
      state = AsyncData(
        state.value!.copyWith(isMicMuted: newMicMuted),
      );
    }
  }

  void toggleHandRaise() {
    if (state.value != null) {
      final newHandState = !state.value!.isHandRaised;
      state = AsyncData(
        state.value!.copyWith(isHandRaised: newHandState),
      );

      final user = ref.read(authProvider).user;
      final profile = ref.read(userProvider).value;
      if (user != null) {
        _repository.broadcastHandRaise(
          stageId,
          user.id,
          profile?.name ?? 'Builder',
          profile?.avatarUrl ?? '',
          newHandState,
        );
      }
    }
  }

  void promoteToSpeaker(String participantId) {
    if (state.value == null) return;
    final current = state.value!;
    final participantIndex =
        current.audience.indexWhere((p) => p.id == participantId);
    if (participantIndex == -1) return;

    final participant = current.audience[participantIndex];
    final updatedAudience = current.audience
        .where((p) => p.id != participantId)
        .toList();

    final currentUserId = ref.read(authProvider).user?.id;
    if (participantId == currentUserId) {
      _audioService.setSpeakerRole(true);
    }

    final newSpeaker = StageSpeaker(
      id: participant.id,
      name: participant.name,
      role: 'Speaker • Invited',
      avatar: participant.avatar,
      isMuted: false,
      isSpeaking: false,
      archetype: 'Seeker',
    );

    state = AsyncData(
      current.copyWith(
        audience: updatedAudience,
        speakers: [...current.speakers, newSpeaker],
      ),
    );

    _repository.broadcastSpeakerPromotion(
      stageId,
      participant.id,
      participant.name,
      participant.avatar,
    );
  }

  void sendReaction(String emoji) {
    if (state.value == null) return;

    final randomX = 0.2 + (Random().nextDouble() * 0.6);
    final reaction = StageReaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      emoji: emoji,
      xOffset: randomX,
    );

    _repository.sendReaction(state.value!.stageId, emoji, randomX);

    state = AsyncData(
      state.value!.copyWith(
        activeReactions: [...state.value!.activeReactions, reaction],
      ),
    );

    // Auto cleanup after 2 seconds — stored so it can be cancelled on dispose.
    final timer = Timer(const Duration(seconds: 2), () {
      if (state.value != null) {
        state = AsyncData(
          state.value!.copyWith(
            activeReactions: state.value!.activeReactions
                .where((r) => r.id != reaction.id)
                .toList(),
          ),
        );
      }
    });
    _reactionTimers.add(timer);
  }
}

/// Family provider — call [stageProvider('stage_1')] to get a specific stage.
/// Each unique stageId gets its own isolated notifier.
final stageProvider =
    AsyncNotifierProvider.family<StageNotifier, StageState, String>(
      (stageId) => StageNotifier(stageId),
    );
