import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stage_provider.dart';

abstract class StageRepository {
  Future<StageState> getStageDetails(String stageId);
  Future<void> sendReaction(String stageId, String emoji, double xOffset);
}

class MockStageRepository implements StageRepository {
  @override
  Future<StageState> getStageDetails(String stageId) async {
    await Future.delayed(const Duration(milliseconds: 300));
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

  @override
  Future<void> sendReaction(String stageId, String emoji, double xOffset) async {
    // In a real app, this would push to Supabase Realtime channel
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

final stageRepositoryProvider = Provider<StageRepository>((ref) {
  return MockStageRepository();
});
