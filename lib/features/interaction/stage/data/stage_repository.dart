import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stage_provider.dart';

abstract class StageRepository {
  Future<StageState> getStageDetails(String stageId);
  Future<List<StageState>> getActiveStages();
  Future<void> sendReaction(String stageId, String emoji, double xOffset);
  Future<void> broadcastHandRaise(
    String stageId,
    String userId,
    String userName,
    String userAvatar,
    bool hasRaised,
  );
  Future<void> broadcastSpeakerPromotion(
    String stageId,
    String participantId,
    String name,
    String avatar,
  );
  RealtimeChannel subscribeToStage(
    String stageId, {
    required void Function(String emoji, double xOffset) onReaction,
    required void Function(
      String userId,
      String userName,
      String userAvatar,
      bool hasRaised,
    ) onHandRaise,
    required void Function(String participantId, String name, String avatar)
        onSpeakerPromotion,
  });
  void unsubscribeFromStage(RealtimeChannel channel);
}

class SupabaseStageRepository implements StageRepository {
  final SupabaseClient _supabase;

  SupabaseStageRepository(this._supabase);

  final List<StageState> _stages = [
    StageState(
      stageId: 'stage_1',
      title: 'Founder Fireside: Zero to Scale',
      topic:
          'Live Q&A on early traction, product-market fit, and team velocity',
      communityName: 'Startup Founders',
      isMicMuted: true,
      isHandRaised: false,
      speakers: [
        StageSpeaker(
          id: 'spk_1',
          name: 'Sarah Chen',
          role: 'Host • Founder & YC Alum',
          avatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
          isMuted: false,
          isSpeaking: true,
          archetype: 'Strategist',
        ),
        StageSpeaker(
          id: 'spk_2',
          name: 'Marcus Thorne',
          role: 'Speaker • Staff Architect',
          avatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
          isMuted: false,
          isSpeaking: false,
          archetype: 'Builder',
        ),
      ],
      audience: [
        StageParticipant(
          id: 'p_1',
          name: 'David Kim',
          avatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
          hasHandRaised: true,
        ),
        StageParticipant(
          id: 'p_2',
          name: 'Jessica Wu',
          avatar:
              'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
        ),
      ],
      activeReactions: [],
    ),
    StageState(
      stageId: 'stage_fellowship',
      title: 'Faith & Technology Fellowship',
      topic:
          'Spontaneous audio room on building ethical software with Christian principles',
      communityName: 'Christian Technologists',
      isMicMuted: true,
      isHandRaised: false,
      speakers: [
        StageSpeaker(
          id: 'spk_3',
          name: 'Jonathan Rivera',
          role: 'Host • Pastor & Dev',
          avatar:
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
          isMuted: false,
          isSpeaking: true,
          archetype: 'Visionary',
        ),
      ],
      audience: [
        StageParticipant(
          id: 'p_3',
          name: 'Hannah Brooks',
          avatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
          hasHandRaised: false,
        ),
      ],
      activeReactions: [],
    ),
  ];

  @override
  Future<List<StageState>> getActiveStages() async {
    return _stages;
  }

  @override
  Future<StageState> getStageDetails(String stageId) async {
    return _stages.firstWhere(
      (s) => s.stageId == stageId || s.stageId == 'stage_$stageId',
      orElse: () => _stages.first.copyWith(stageId: stageId),
    );
  }

  @override
  Future<void> sendReaction(
    String stageId,
    String emoji,
    double xOffset,
  ) async {
    try {
      final channel = _supabase.channel('stage_$stageId');
      await channel.sendBroadcastMessage(
        event: 'stage_reaction',
        payload: {
          'emoji': emoji,
          'xOffset': xOffset,
          'senderId': _supabase.auth.currentUser?.id ?? 'anon',
        },
      );
    } catch (_) {
      // Offline fallback
    }
  }

  @override
  Future<void> broadcastHandRaise(
    String stageId,
    String userId,
    String userName,
    String userAvatar,
    bool hasRaised,
  ) async {
    try {
      final channel = _supabase.channel('stage_$stageId');
      await channel.sendBroadcastMessage(
        event: 'stage_hand_raise',
        payload: {
          'userId': userId,
          'userName': userName,
          'userAvatar': userAvatar,
          'hasRaised': hasRaised,
        },
      );
    } catch (_) {
      // Offline fallback
    }
  }

  @override
  Future<void> broadcastSpeakerPromotion(
    String stageId,
    String participantId,
    String name,
    String avatar,
  ) async {
    try {
      final channel = _supabase.channel('stage_$stageId');
      await channel.sendBroadcastMessage(
        event: 'stage_speaker_promotion',
        payload: {
          'participantId': participantId,
          'name': name,
          'avatar': avatar,
        },
      );
    } catch (_) {
      // Offline fallback
    }
  }

  @override
  RealtimeChannel subscribeToStage(
    String stageId, {
    required void Function(String emoji, double xOffset) onReaction,
    required void Function(
      String userId,
      String userName,
      String userAvatar,
      bool hasRaised,
    ) onHandRaise,
    required void Function(String participantId, String name, String avatar)
        onSpeakerPromotion,
  }) {
    final channel = _supabase.channel('stage_$stageId');
    channel.onBroadcast(
      event: 'stage_reaction',
      callback: (payload) {
        final emoji = payload['emoji']?.toString() ?? '🔥';
        final xOffset = (payload['xOffset'] as num?)?.toDouble() ?? 0.5;
        onReaction(emoji, xOffset);
      },
    );
    channel.onBroadcast(
      event: 'stage_hand_raise',
      callback: (payload) {
        final userId = payload['userId']?.toString() ?? '';
        final userName = payload['userName']?.toString() ?? 'Attendee';
        final userAvatar = payload['userAvatar']?.toString() ?? '';
        final hasRaised = payload['hasRaised'] as bool? ?? false;
        onHandRaise(userId, userName, userAvatar, hasRaised);
      },
    );
    channel.onBroadcast(
      event: 'stage_speaker_promotion',
      callback: (payload) {
        final participantId = payload['participantId']?.toString() ?? '';
        final name = payload['name']?.toString() ?? 'Speaker';
        final avatar = payload['avatar']?.toString() ?? '';
        onSpeakerPromotion(participantId, name, avatar);
      },
    );
    channel.subscribe();
    return channel;
  }

  @override
  void unsubscribeFromStage(RealtimeChannel channel) {
    try {
      _supabase.removeChannel(channel);
    } catch (_) {}
  }
}

final stageRepositoryProvider = Provider<StageRepository>((ref) {
  return SupabaseStageRepository(Supabase.instance.client);
});
