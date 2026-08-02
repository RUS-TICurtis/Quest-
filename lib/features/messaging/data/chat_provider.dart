import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MessageType { text, voice, voiceNote, linkPreview }

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final MessageType type;
  final int voiceDurationSeconds;
  final String? audioDuration;
  final List<double>? waveform;
  final String? linkTitle;
  final String? linkSubtitle;
  final String? linkTargetRoute;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    this.type = MessageType.text,
    this.voiceDurationSeconds = 0,
    this.audioDuration,
    this.waveform,
    this.linkTitle,
    this.linkSubtitle,
    this.linkTargetRoute,
  });

  String get message => text;
  String? get linkDescription => linkSubtitle;
  String? get linkUrl => linkTargetRoute;
}

class ChatThread {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final int unread;
  final bool isAiCoach;
  final List<ChatMessage> messages;
  final List<String> aiSuggestions;

  const ChatThread({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    this.isAiCoach = false,
    required this.messages,
    this.aiSuggestions = const [],
  });

  String get name => title;
  String get lastMessage => subtitle;
  int get unreadCount => unread;
  bool get isAiGuide => isAiCoach;

  ChatThread copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? time,
    int? unread,
    bool? isAiCoach,
    List<ChatMessage>? messages,
    List<String>? aiSuggestions,
  }) {
    return ChatThread(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      time: time ?? this.time,
      unread: unread ?? this.unread,
      isAiCoach: isAiCoach ?? this.isAiCoach,
      messages: messages ?? this.messages,
      aiSuggestions: aiSuggestions ?? this.aiSuggestions,
    );
  }
}

class ChatState {
  final List<ChatThread> threads;

  const ChatState({required this.threads});

  ChatThread? getThreadById(String id) {
    try {
      final cleanId = id.replaceAll(RegExp(r'^t'), '');
      return threads.firstWhere(
        (t) => t.id == id || t.id == cleanId || 't${t.id}' == id,
      );
    } catch (_) {
      return threads.isNotEmpty ? threads.first : null;
    }
  }

  ChatState copyWith({List<ChatThread>? threads}) {
    return ChatState(threads: threads ?? this.threads);
  }
}

class ChatNotifier extends Notifier<ChatState> {
  @override
  ChatState build() {
    return ChatState(
      threads: [
        ChatThread(
          id: 'ai_coach',
          title: 'Quest AI Guide',
          subtitle: 'Here is a recommended connection for you based on Flutter...',
          time: 'Just now',
          unread: 1,
          isAiCoach: true,
          aiSuggestions: [
            'Find events near me',
            'Connect with Flutter developers',
            'How do I earn more XP?',
          ],
          messages: [
            const ChatMessage(
              id: 'm1',
              text: 'Hey Alex! 👋 I noticed you\'re exploring mobile architecture. There\'s an upcoming workshop tomorrow that matches your interests!',
              isMe: false,
              time: '10:00 AM',
            ),
            const ChatMessage(
              id: 'm2',
              text: 'Here is the event details card:',
              isMe: false,
              time: '10:01 AM',
              type: MessageType.linkPreview,
              linkTitle: 'Flutter Architecture Workshop',
              linkSubtitle: 'Tomorrow @ 6:30 PM • Tech Campus Room 4B',
              linkTargetRoute: 'quest://events/2',
            ),
            const ChatMessage(
              id: 'm3',
              text: 'Would you like me to RSVP for you or send you questions to ask the speaker?',
              isMe: false,
              time: '10:02 AM',
            ),
          ],
        ),
        ChatThread(
          id: '1',
          title: 'Flutter Builders',
          subtitle: 'Sarah: Anyone attending the workshop tomorrow?',
          time: '2m',
          unread: 3,
          isAiCoach: false,
          aiSuggestions: ['I\'ll be there!', 'Can someone share the slides?', 'Looking forward to meeting everyone'],
          messages: [
            const ChatMessage(
              id: 'm10',
              text: 'Hey everyone! Who is heading to the Flutter meetup tomorrow?',
              isMe: false,
              time: '2:15 PM',
            ),
            const ChatMessage(
              id: 'm11',
              text: 'I\'ll be presenting on Riverpod 3.0 state management & clean architecture patterns!',
              isMe: true,
              time: '2:16 PM',
            ),
            const ChatMessage(
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
      ],
    );
  }

  ChatThread? getThreadById(String id) {
    try {
      return state.threads.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  void sendMessage({
    required String threadId,
    required String text,
    MessageType type = MessageType.text,
    int voiceDurationSeconds = 0,
    String? audioDuration,
    List<double>? waveform,
    String? linkTitle,
    String? linkSubtitle,
    String? linkTargetRoute,
  }) {
    final updatedThreads = state.threads.map((thread) {
      if (thread.id == threadId) {
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

        final updatedMessages = [...thread.messages, newMsg];

        return thread.copyWith(
          messages: updatedMessages,
          subtitle: text,
          time: 'Just now',
          unread: 0,
        );
      }
      return thread;
    }).toList();

    state = state.copyWith(threads: updatedThreads);
  }

  void sendVoiceNote(String threadId) {
    sendMessage(
      threadId: threadId,
      text: 'Voice note (0:16)',
      type: MessageType.voiceNote,
      voiceDurationSeconds: 16,
      audioDuration: '0:16',
      waveform: [0.3, 0.6, 0.9, 0.7, 0.4, 0.8, 1.0, 0.6, 0.4, 0.8, 0.5, 0.3],
    );
  }

  void markThreadRead(String threadId) {
    final updatedThreads = state.threads.map((thread) {
      if (thread.id == threadId) {
        return thread.copyWith(unread: 0);
      }
      return thread;
    }).toList();
    state = state.copyWith(threads: updatedThreads);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
