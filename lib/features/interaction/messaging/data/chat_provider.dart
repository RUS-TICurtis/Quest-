import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:quest/features/interaction/messaging/data/chat_repository.dart';

enum MessageType {
  text,
  voice,
  voiceNote,
  linkPreview,
  image,
  video,
  file,
  poll,
  system,
}

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
  final DateTime? sentAt;
  final VMessageStatus? status;
  final VReplyData? replyTo;
  final List<VBubbleReaction> reactions;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final VPollData? pollData;
  final bool isPinned;
  final String? senderName;

  ChatMessage({
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
    this.sentAt,
    this.status,
    this.replyTo,
    this.reactions = const [],
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.pollData,
    this.isPinned = false,
    this.senderName,
  });

  String get message => text;
  String? get linkDescription => linkSubtitle;
  String? get linkUrl => linkTargetRoute;

  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isMe,
    String? time,
    MessageType? type,
    int? voiceDurationSeconds,
    String? audioDuration,
    List<double>? waveform,
    String? linkTitle,
    String? linkSubtitle,
    String? linkTargetRoute,
    DateTime? sentAt,
    VMessageStatus? status,
    VReplyData? replyTo,
    List<VBubbleReaction>? reactions,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    VPollData? pollData,
    bool? isPinned,
    String? senderName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isMe: isMe ?? this.isMe,
      time: time ?? this.time,
      type: type ?? this.type,
      voiceDurationSeconds: voiceDurationSeconds ?? this.voiceDurationSeconds,
      audioDuration: audioDuration ?? this.audioDuration,
      waveform: waveform ?? this.waveform,
      linkTitle: linkTitle ?? this.linkTitle,
      linkSubtitle: linkSubtitle ?? this.linkSubtitle,
      linkTargetRoute: linkTargetRoute ?? this.linkTargetRoute,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      replyTo: replyTo ?? this.replyTo,
      reactions: reactions ?? this.reactions,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      pollData: pollData ?? this.pollData,
      isPinned: isPinned ?? this.isPinned,
      senderName: senderName ?? this.senderName,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      isMe: json['isMe'] as bool,
      time: json['time'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${json['type']}',
        orElse: () => MessageType.text,
      ),
      voiceDurationSeconds: json['voiceDurationSeconds'] as int? ?? 0,
      audioDuration: json['audioDuration'] as String?,
      waveform: (json['waveform'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList(),
      linkTitle: json['linkTitle'] as String?,
      linkSubtitle: json['linkSubtitle'] as String?,
      linkTargetRoute: json['linkTargetRoute'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      isPinned: json['isPinned'] as bool? ?? false,
      senderName: json['senderName'] as String?,
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
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'isPinned': isPinned,
      'senderName': senderName,
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
  final bool isMuted;
  final bool isPinned;
  final bool isChannel;
  final bool isGroup;
  final int? memberCount;
  final String? userHandle;
  final String? avatarUrl;
  final bool isOnline;
  final String? lastSeenText;
  final String? pinnedMessageText;

  ChatThread({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    this.isAiCoach = false,
    required this.messages,
    this.aiSuggestions = const [],
    this.isMuted = false,
    this.isPinned = false,
    this.isChannel = false,
    this.isGroup = false,
    this.memberCount,
    this.userHandle,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenText,
    this.pinnedMessageText,
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
    bool? isMuted,
    bool? isPinned,
    bool? isChannel,
    bool? isGroup,
    int? memberCount,
    String? userHandle,
    String? avatarUrl,
    bool? isOnline,
    String? lastSeenText,
    String? pinnedMessageText,
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
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      isChannel: isChannel ?? this.isChannel,
      isGroup: isGroup ?? this.isGroup,
      memberCount: memberCount ?? this.memberCount,
      userHandle: userHandle ?? this.userHandle,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeenText: lastSeenText ?? this.lastSeenText,
      pinnedMessageText: pinnedMessageText ?? this.pinnedMessageText,
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
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      aiSuggestions:
          (json['aiSuggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isMuted: json['isMuted'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isChannel: json['isChannel'] as bool? ?? false,
      isGroup: json['isGroup'] as bool? ?? false,
      memberCount: json['memberCount'] as int?,
      userHandle: json['userHandle'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenText: json['lastSeenText'] as String?,
      pinnedMessageText: json['pinnedMessageText'] as String?,
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
      'isMuted': isMuted,
      'isPinned': isPinned,
      'isChannel': isChannel,
      'isGroup': isGroup,
      'memberCount': memberCount,
      'userHandle': userHandle,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeenText': lastSeenText,
      'pinnedMessageText': pinnedMessageText,
    };
  }
}

class ChatState {
  final List<ChatThread> threads;

  ChatState({required this.threads});

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

class ChatNotifier extends StreamNotifier<ChatState> {
  late final ChatRepository _repository;

  @override
  Stream<ChatState> build() {
    _repository = ref.watch(chatRepositoryProvider);
    return _repository.getThreadsStream().map(
      (threads) => ChatState(threads: threads),
    );
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
    VReplyData? replyTo,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    VPollData? pollData,
  }) async {
    await _repository.sendMessage(
      threadId: threadId,
      text: text,
      type: type,
      voiceDurationSeconds: voiceDurationSeconds,
      audioDuration: audioDuration,
      waveform: waveform,
      linkTitle: linkTitle,
      linkSubtitle: linkSubtitle,
      linkTargetRoute: linkTargetRoute,
      replyTo: replyTo,
      mediaUrl: mediaUrl,
      fileName: fileName,
      fileSize: fileSize,
      pollData: pollData,
    );
  }

  Future<void> sendVoiceNote(String threadId, {int durationSeconds = 5}) async {
    await _repository.sendVoiceNote(threadId);
  }

  Future<void> markThreadRead(String threadId) async {
    await _repository.markThreadRead(threadId);
  }

  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
  }) async {
    await _repository.toggleReaction(
      threadId: threadId,
      messageId: messageId,
      emoji: emoji,
    );
  }

  Future<void> votePoll({
    required String threadId,
    required String messageId,
    required String optionId,
  }) async {
    await _repository.votePoll(
      threadId: threadId,
      messageId: messageId,
      optionId: optionId,
    );
  }

  Future<void> pinMessage({
    required String threadId,
    required String messageId,
  }) async {
    await _repository.pinMessage(threadId: threadId, messageId: messageId);
  }

  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  }) async {
    await _repository.deleteMessage(threadId: threadId, messageId: messageId);
  }
}

final chatProvider = StreamNotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});
