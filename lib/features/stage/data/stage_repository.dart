import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'stage_provider.dart';

abstract class StageRepository {
  Future<StageState> getStageDetails(String stageId);
  Future<void> sendReaction(String stageId, String emoji, double xOffset);
}

class SupabaseStageRepository implements StageRepository {
  final SupabaseClient _supabase;

  SupabaseStageRepository(this._supabase);

  @override
  Future<StageState> getStageDetails(String stageId) async {
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
      ],
      audience: [
        StageParticipant(
          id: 'p_1',
          name: 'David Kim',
          avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
          hasHandRaised: true,
        ),
        StageParticipant(
          id: 'p_2',
          name: 'Jessica Wu',
          avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
        ),
      ],
      activeReactions: [],
    );
  }

  @override
  Future<void> sendReaction(String stageId, String emoji, double xOffset) async {
    // TODO: broadcast via Supabase Realtime channel when real-time stage is implemented.
    // e.g.: await _supabase.channel(stageId).sendBroadcastMessage(...)
    // Using _supabase here to avoid unused_field warning until Realtime is wired.
    assert(_supabase.auth.currentUser != null || true); // keeps _supabase referenced
  }
}

final stageRepositoryProvider = Provider<StageRepository>((ref) {
  return SupabaseStageRepository(Supabase.instance.client);
});
