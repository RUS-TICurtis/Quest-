import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_repository.dart';

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

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isMe: json['isMe'] as bool,
      time: json['time'] as String,
      type: MessageType.values.firstWhere((e) => e.toString() == 'MessageType.${json['type']}', orElse: () => MessageType.text),
      voiceDurationSeconds: json['voiceDurationSeconds'] as int? ?? 0,
      audioDuration: json['audioDuration'] as String?,
      waveform: (json['waveform'] as List<dynamic>?)?.map((e) => (e as num).toDouble()).toList(),
      linkTitle: json['linkTitle'] as String?,
      linkSubtitle: json['linkSubtitle'] as String?,
      linkTargetRoute: json['linkTargetRoute'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'time': time,
      'type': type.toString().split('.').last,
      'voiceDurationSeconds': voiceDurationSeconds,
      'audioDuration': audioDuration,
      'waveform': waveform,
      'linkTitle': linkTitle,
      'linkSubtitle': linkSubtitle,
      'linkTargetRoute': linkTargetRoute,
    };
  }
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

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      time: json['time'] as String,
      unread: json['unread'] as int? ?? 0,
      isAiCoach: json['isAiCoach'] as bool? ?? false,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiSuggestions: (json['aiSuggestions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'time': time,
      'unread': unread,
      'isAiCoach': isAiCoach,
      'messages': messages.map((e) => e.toJson()).toList(),
      'aiSuggestions': aiSuggestions,
    };
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

class ChatNotifier extends AsyncNotifier<ChatState> {
  late final ChatRepository _repository;

  @override
  Future<ChatState> build() async {
    _repository = ref.watch(chatRepositoryProvider);
    final threads = await _repository.getThreads();
    return ChatState(threads: threads);
  }

  ChatThread? getThreadById(String id) {
    return state.value?.getThreadById(id);
  }

  Future<void> sendMessage({
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
    final updatedThread = await _repository.sendMessage(
      threadId: threadId,
      text: text,
      type: type,
      voiceDurationSeconds: voiceDurationSeconds,
      audioDuration: audioDuration,
      waveform: waveform,
      linkTitle: linkTitle,
      linkSubtitle: linkSubtitle,
      linkTargetRoute: linkTargetRoute,
    );

    state = AsyncData(state.value!.copyWith(
      threads: state.value!.threads.map((t) => t.id == threadId ? updatedThread : t).toList(),
    ));
  }

  Future<void> sendVoiceNote(String threadId) async {
    await _repository.sendVoiceNote(threadId);
    // Reload state after sending
    final threads = await _repository.getThreads();
    state = AsyncData(state.value!.copyWith(threads: threads));
  }

  Future<void> markThreadRead(String threadId) async {
    await _repository.markThreadRead(threadId);
    final updatedThreads = state.value?.threads.map((thread) {
      if (thread.id == threadId) {
        return thread.copyWith(unread: 0);
      }
      return thread;
    }).toList();
    
    if (updatedThreads != null) {
      state = AsyncData(state.value!.copyWith(threads: updatedThreads));
    }
  }
}

final chatProvider = AsyncNotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
