import 'package:flutter_test/flutter_test.dart';
import 'package:quest/core/audio/stage_audio_service.dart';
import 'package:quest/features/interaction/stage/data/stage_provider.dart';

void main() {
  group('Stage Domain & Realtime Model Tests', () {
    test('instantiates and serializes StageSpeaker correctly', () {
      final speaker = StageSpeaker(
        id: 'spk_1',
        name: 'Sarah Chen',
        role: 'Host • Founder & YC Alum',
        avatar: 'https://example.com/avatar.jpg',
        isMuted: false,
        isSpeaking: true,
        archetype: 'Strategist',
      );

      expect(speaker.id, equals('spk_1'));
      expect(speaker.name, equals('Sarah Chen'));
      expect(speaker.isSpeaking, isTrue);

      final json = speaker.toJson();
      expect(json['id'], equals('spk_1'));
      expect(json['name'], equals('Sarah Chen'));
      expect(json['role'], equals('Host • Founder & YC Alum'));
      expect(json['isSpeaking'], isTrue);

      final fromJson = StageSpeaker.fromJson(json);
      expect(fromJson.id, equals(speaker.id));
      expect(fromJson.name, equals(speaker.name));
      expect(fromJson.archetype, equals('Strategist'));
    });

    test('instantiates and serializes StageParticipant and hand raise states', () {
      final participant = StageParticipant(
        id: 'p_1',
        name: 'David Kim',
        avatar: 'https://example.com/david.jpg',
        hasHandRaised: true,
      );

      expect(participant.id, equals('p_1'));
      expect(participant.hasHandRaised, isTrue);

      final lowered = participant.copyWith(hasHandRaised: false);
      expect(lowered.hasHandRaised, isFalse);

      final json = participant.toJson();
      expect(json['hasHandRaised'], isTrue);

      final fromJson = StageParticipant.fromJson(json);
      expect(fromJson.id, equals('p_1'));
      expect(fromJson.hasHandRaised, isTrue);
    });

    test('instantiates StageReaction and StageState correctly', () {
      final reaction = StageReaction(
        id: 'r_1',
        emoji: '🔥',
        xOffset: 0.45,
      );

      final state = StageState(
        stageId: 'stage_test',
        title: 'Community Fireside',
        topic: 'Discussing real-world faith & technology',
        communityName: 'Builders Fellowship',
        isMicMuted: true,
        isHandRaised: false,
        speakers: [
          StageSpeaker(
            id: 'spk_test',
            name: 'Speaker',
            role: 'Host',
            avatar: '',
          ),
        ],
        audience: [
          StageParticipant(
            id: 'p_test',
            name: 'Listener',
            avatar: '',
          ),
        ],
        activeReactions: [reaction],
      );

      expect(state.stageId, equals('stage_test'));
      expect(state.speakers.length, equals(1));
      expect(state.audience.length, equals(1));
      expect(state.activeReactions.length, equals(1));
      expect(state.activeReactions.first.emoji, equals('🔥'));

      final json = state.toJson();
      expect(json['stageId'], equals('stage_test'));
      expect(json['title'], equals('Community Fireside'));

      final fromJson = StageState.fromJson(json);
      expect(fromJson.stageId, equals('stage_test'));
      expect(fromJson.speakers.first.name, equals('Speaker'));
      expect(fromJson.audience.first.name, equals('Listener'));
    });
  });

  group('Stage Audio Service & Repository Tests', () {
    test('QuestStageAudioService manages audio state and roles correctly', () async {
      final audioService = QuestStageAudioService();

      expect(audioService.connectionState, equals(AudioConnectionState.disconnected));
      expect(audioService.isMicrophoneMuted, isTrue);

      await audioService.setMicrophoneMuted(false);
      expect(audioService.isMicrophoneMuted, isFalse);

      await audioService.setSpeakerRole(true);
      await audioService.setMicrophoneMuted(false);
      expect(audioService.isMicrophoneMuted, isFalse);

      await audioService.setSpeakerRole(false);
      expect(audioService.isMicrophoneMuted, isTrue);

      await audioService.leaveStage();
      expect(audioService.connectionState, equals(AudioConnectionState.disconnected));
      expect(audioService.currentStageId, isNull);

      audioService.dispose();
    });

    test('StageState and StageSpeaker correctly represent host and speaker roles', () {
      final host = StageSpeaker(
        id: 'host_123',
        name: 'Pastor David',
        role: 'Host • Creator',
        avatar: 'https://example.com/pastor.jpg',
        isMuted: false,
        isSpeaking: true,
        archetype: 'Visionary',
      );

      final stage = StageState(
        stageId: 'stage_custom_1',
        title: 'Sunday Night Fellowship',
        topic: 'Scripture meditation and life journey discussion',
        communityName: 'Living Faith Fellowship',
        isMicMuted: false,
        isHandRaised: false,
        speakers: [host],
        audience: [],
      );

      expect(stage.speakers.length, equals(1));
      expect(stage.speakers.first.id, equals('host_123'));
      expect(stage.speakers.first.name, equals('Pastor David'));
      expect(stage.speakers.first.role, equals('Host • Creator'));
      expect(stage.speakers.first.isSpeaking, isTrue);
      expect(stage.communityName, equals('Living Faith Fellowship'));
    });
  });
}

