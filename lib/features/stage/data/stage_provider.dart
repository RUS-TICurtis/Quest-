import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StageSpeaker {
  final String id;
  final String name;
  final String role;
  final String avatar;
  final bool isMuted;
  final bool isSpeaking;
  final String archetype;

  const StageSpeaker({
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
}

class StageParticipant {
  final String id;
  final String name;
  final String avatar;
  final bool hasHandRaised;

  const StageParticipant({
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
}

class StageReaction {
  final String id;
  final String emoji;
  final double xOffset; // 0.0 to 1.0

  const StageReaction({
    required this.id,
    required this.emoji,
    required this.xOffset,
  });
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

  const StageState({
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
}

class StageNotifier extends Notifier<StageState> {
  @override
  StageState build() {
    return const StageState(
      stageId: 'stage_1',
      title: 'Founder Fireside: Zero to Scale',
      topic: 'Live Q&A on early traction, product-market fit, and team velocity',
      communityName: 'Startup Founders',
      isMicMuted: true,
      isHandRaised: false,
      speakers: [
        StageSpeaker(
          id: 'spk_1',
          name: 'Sarah Chen',
          role: 'Host • Founder & YC Alum',
          avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
          isMuted: false,
          isSpeaking: true,
          archetype: 'Strategist',
        ),
        StageSpeaker(
          id: 'spk_2',
          name: 'Marcus Thorne',
          role: 'Speaker • Staff Architect',
          avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          isMuted: false,
          isSpeaking: false,
          archetype: 'Builder',
        ),
        StageSpeaker(
          id: 'spk_3',
          name: 'Elena Rostova',
          role: 'Speaker • Design Director',
          avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
          isMuted: true,
          isSpeaking: false,
          archetype: 'Pioneer',
        ),
      ],
      audience: [
        StageParticipant(
          id: 'aud_1',
          name: 'David Kim',
          avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
          hasHandRaised: true,
        ),
        StageParticipant(
          id: 'aud_2',
          name: 'Jessica Wu',
          avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
          hasHandRaised: false,
        ),
        StageParticipant(
          id: 'aud_3',
          name: 'Lucas Vance',
          avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200',
          hasHandRaised: false,
        ),
        StageParticipant(
          id: 'aud_4',
          name: 'Amara Okafor',
          avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
          hasHandRaised: true,
        ),
        StageParticipant(
          id: 'aud_5',
          name: 'Liam Patel',
          avatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=200',
          hasHandRaised: false,
        ),
      ],
    );
  }

  void toggleMic() {
    state = state.copyWith(isMicMuted: !state.isMicMuted);
  }

  void toggleHandRaise() {
    state = state.copyWith(isHandRaised: !state.isHandRaised);
  }

  void sendReaction(String emoji) {
    final randomX = 0.2 + (Random().nextDouble() * 0.6);
    final reaction = StageReaction(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
      emoji: emoji,
      xOffset: randomX,
    );

    state = state.copyWith(
      activeReactions: [...state.activeReactions, reaction],
    );

    // Auto cleanup after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      state = state.copyWith(
        activeReactions: state.activeReactions.where((r) => r.id != reaction.id).toList(),
      );
    });
  }
}

final stageProvider = NotifierProvider<StageNotifier, StageState>(() {
  return StageNotifier();
});
