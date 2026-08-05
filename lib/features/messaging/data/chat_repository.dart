import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_provider.dart';

abstract class ChatRepository {
  Future<List<ChatThread>> getThreads();
  Future<ChatThread> sendMessage({
    required String threadId,
    required String text,
    MessageType type = MessageType.text,
    int voiceDurationSeconds = 0,
    String? audioDuration,
    List<double>? waveform,
    String? linkTitle,
    String? linkSubtitle,
    String? linkTargetRoute,
  });
  Future<void> sendVoiceNote(String threadId);
  Future<void> markThreadRead(String threadId);
}

class MockChatRepository implements ChatRepository {
  final List<ChatThread> _threads = [
        ChatThread(
          id: 'ai_coach',
          title: 'Quest AI Guide',
          subtitle: 'Here is a recommended connection for you based on Flutter...',
          time: 'Just now',
          unread: 1,
          isAiCoach: true,
          aiSuggestions: const [
            'Find events near me',
            'Connect with Flutter developers',
            'How do I earn more XP?',
          ],
          messages: const [
            ChatMessage(
              id: 'm1',
              text: 'Hey Alex! 👋 I noticed you\'re exploring mobile architecture. There\'s an upcoming workshop tomorrow that matches your interests!',
              isMe: false,
              time: '10:00 AM',
            ),
            ChatMessage(
              id: 'm2',
              text: 'Here is the event details card:',
              isMe: false,
              time: '10:01 AM',
              type: MessageType.linkPreview,
              linkTitle: 'Flutter Architecture Workshop',
              linkSubtitle: 'Tomorrow @ 6:30 PM • Tech Campus Room 4B',
              linkTargetRoute: 'quest://events/2',
            ),
            ChatMessage(
              id: 'm3',
              text: 'Would you like me to RSVP for you or send you questions to ask the speaker?',
              isMe: false,
              time: '10:02 AM',
            ),
          ],
        ),
        const ChatThread(
          id: '1',
          title: 'Flutter Builders',
          subtitle: 'Sarah: Anyone attending the workshop tomorrow?',
          time: '2m',
          unread: 3,
          isAiCoach: false,
          aiSuggestions: ['I\'ll be there!', 'Can someone share the slides?', 'Looking forward to meeting everyone'],
          messages: [
            ChatMessage(
              id: 'm10',
              text: 'Hey everyone! Who is heading to the Flutter meetup tomorrow?',
              isMe: false,
              time: '2:15 PM',
            ),
            ChatMessage(
              id: 'm11',
              text: 'I\'ll be presenting on Riverpod 3.0 state management & clean architecture patterns!',
              isMe: true,
              time: '2:16 PM',
            ),
            ChatMessage(
              id: 'm12',
              text: 'Voice note from Sarah',
              isMe: false,
              time: '2:18 PM',
              type: MessageType.voiceNote,
              voiceDurationSeconds: 24,
              audioDuration: '0:24',
              waveform: [0.2, 0.4, 0.8, 0.5, 0.9, 0.7, 0.3, 0.6, 0.8, 0.4, 0.2, 0.7, 0.9, 0.5, 0.3],
            ),
          ],
        ),
        const ChatThread(
          id: '2',
          title: 'Startup Founders',
          subtitle: 'Marcus: Pitch deck feedback session starts in 1 hour',
          time: '1h',
          unread: 0,
          isAiCoach: false,
          messages: [
            ChatMessage(
              id: 'm20',
              text: 'Pitch deck feedback session starts in 1 hour at the downtown hub!',
              isMe: false,
              time: '1:00 PM',
            ),
          ],
        ),
        const ChatThread(
          id: '3',
          title: 'Sarah Chen',
          subtitle: 'Shared an event with you: Tech Startup Mixer',
          time: '3h',
          unread: 0,
          isAiCoach: false,
          messages: [
            ChatMessage(
              id: 'm30',
              text: 'Hey Alex! Are you going to the Tech Startup Mixer tonight?',
              isMe: false,
              time: '11:30 AM',
            ),
            ChatMessage(
              id: 'm31',
              text: 'Tech Startup Mixer',
              isMe: false,
              time: '11:31 AM',
              type: MessageType.linkPreview,
              linkTitle: 'Tech Startup Mixer',
              linkSubtitle: 'Tonight @ 7:00 PM • Downtown Innovation Hub',
              linkTargetRoute: 'quest://events/1',
            ),
          ],
        ),
      ];

  @override
  Future<List<ChatThread>> getThreads() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_threads);
  }

  @override
  Future<ChatThread> sendMessage({
    required String threadId,
    required String text,
    MessageType type = MessageType.text,
    int voiceDurationSeconds = 0,
    String? audioDuration,
    List<double>? waveform,
    String? linkTitle,
    String? linkSubtitle,
    String? linkTargetRoute,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index == -1) throw Exception('Thread not found');
    
    final thread = _threads[index];
    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      time: 'Just now',
      type: type,
      voiceDurationSeconds: voiceDurationSeconds,
      audioDuration: audioDuration,
      waveform: waveform,
      linkTitle: linkTitle,
      linkSubtitle: linkSubtitle,
      linkTargetRoute: linkTargetRoute,
    );

    final updatedThread = thread.copyWith(
      messages: [...thread.messages, newMsg],
      subtitle: text,
      time: 'Just now',
      unread: 0,
    );
    
    _threads[index] = updatedThread;
    return updatedThread;
  }

  @override
  Future<void> sendVoiceNote(String threadId) async {
    await sendMessage(
      threadId: threadId,
      text: 'Voice note (0:16)',
      type: MessageType.voiceNote,
      voiceDurationSeconds: 16,
      audioDuration: '0:16',
      waveform: const [0.3, 0.6, 0.9, 0.7, 0.4, 0.8, 1.0, 0.6, 0.4, 0.8, 0.5, 0.3],
    );
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) {
      _threads[index] = _threads[index].copyWith(unread: 0);
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return MockChatRepository();
});
