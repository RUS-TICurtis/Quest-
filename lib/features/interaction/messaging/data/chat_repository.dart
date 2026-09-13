import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:quest/core/network/network_info.dart';
import 'package:quest/core/storage/local_database_service.dart';
import 'package:quest/core/storage/models/local_chat_room.dart';
import 'package:quest/core/storage/models/local_chat_message.dart';
import 'chat_provider.dart';

abstract class ChatRepository {
  Stream<List<ChatThread>> getThreadsStream();
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
  });
  Future<void> sendVoiceNote(String threadId);
  Future<void> markThreadRead(String threadId);
  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
  });
  Future<void> votePoll({
    required String threadId,
    required String messageId,
    required String optionId,
  });
  Future<void> pinMessage({
    required String threadId,
    required String messageId,
  });
  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  });
}

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _supabase;
  final NetworkInfo _networkInfo;
  final LocalDatabaseService _localDb;

  final StreamController<List<ChatThread>> _demoStreamController =
      StreamController<List<ChatThread>>.broadcast();
  List<ChatThread>? _cachedThreads;

  SupabaseChatRepository(this._supabase, this._networkInfo, this._localDb);

  @override
  Stream<List<ChatThread>> getThreadsStream() async* {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _cachedThreads ??= _generateTelegramDemoThreads();
      yield _cachedThreads!;
      yield* _demoStreamController.stream;
      return;
    }

    // Trigger background sync
    _syncThreads(userId);

    // Yield initial local data
    final localThreads = _buildThreadsFromLocal(userId);
    if (localThreads.length <= 1) {
      // If local DB only has the AI coach or empty, prepend rich demo threads
      _cachedThreads ??= _generateTelegramDemoThreads();
      yield _cachedThreads!;
    } else {
      yield localThreads;
    }

    // Listen to local DB changes and demo controller updates
    await for (final _ in _localDb.chatRoomsBox.watch()) {
      yield _buildThreadsFromLocal(userId);
    }
  }

  List<ChatThread> _buildThreadsFromLocal(String userId) {
    final threads = <ChatThread>[];
    for (var localRoom in _localDb.chatRoomsBox.values) {
      final localMessages = _localDb.chatMessagesBox.values
          .where((m) => m.roomId == localRoom.roomId)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final messages = localMessages.map((m) {
        return ChatMessage(
          id: m.messageId,
          text: m.text,
          isMe: m.senderId == userId,
          time: DateTime.tryParse(m.createdAt)?.toLocal().toString() ?? m.createdAt,
          sentAt: DateTime.tryParse(m.createdAt),
          type: MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == m.type,
            orElse: () => MessageType.text,
          ),
          status: VMessageStatus.read,
        );
      }).toList();

      threads.add(
        ChatThread(
          id: localRoom.roomId,
          title: localRoom.name,
          subtitle: localRoom.lastMessageText,
          time: localRoom.lastMessageTime,
          unread: localRoom.unreadCount,
          isAiCoach: localRoom.isAiCoach,
          messages: messages,
        ),
      );
    }

    final demoThreads = _generateTelegramDemoThreads();
    for (var d in demoThreads) {
      if (!threads.any((t) => t.id == d.id)) {
        threads.add(d);
      }
    }

    return threads;
  }

  Future<void> _syncThreads(String userId) async {
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      _syncOutbox(userId);
      return;
    }

    try {
      final participantsData = await _supabase.from('chat_participants').select().eq('userId', userId);

      for (var pData in participantsData) {
        final roomId = pData['roomId'];

        final roomData = await _supabase.from('chat_rooms').select().eq('id', roomId).single();
        
        final localRoom = LocalChatRoom(
          roomId: roomId,
          name: roomData['name'] ?? 'Chat',
          lastMessageText: roomData['lastMessageText'] ?? '',
          lastMessageTime: roomData['lastMessageTime'] ?? '',
          unreadCount: 0,
          isAiCoach: false,
        );
        await _localDb.chatRoomsBox.put(roomId, localRoom);

        final messagesData = await _supabase.from('chat_messages').select().eq('roomId', roomId).order('createdAt', ascending: false).limit(50);

        for (var m in messagesData) {
          final localMsg = LocalChatMessage(
            messageId: m['id'],
            roomId: roomId,
            text: m['text'] ?? '',
            senderId: m['senderId'],
            createdAt: m['createdAt'] ?? '',
            type: m['type'] ?? 'text',
            isPending: false,
          );
          await _localDb.chatMessagesBox.put(localMsg.messageId, localMsg);
        }
      }

      _syncOutbox(userId);
    } catch (_) {
      // Silent sync fallback
    }
  }

  Future<void> _syncOutbox(String userId) async {
    final pendingMessages = _localDb.chatMessagesBox.values.where((m) => m.isPending && m.senderId == userId).toList();
    if (pendingMessages.isEmpty) return;
    
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) return;

    for (var pendingMsg in pendingMessages) {
      try {
        await _supabase.from('chat_messages').insert({
          'roomId': pendingMsg.roomId,
          'senderId': pendingMsg.senderId,
          'text': pendingMsg.text,
          'time': pendingMsg.createdAt,
          'type': pendingMsg.type,
        });

        await _localDb.chatMessagesBox.delete(pendingMsg.messageId);
      } catch (_) {
        // Retry next sync
      }
    }
    _syncThreads(userId);
  }

  List<ChatThread> _generateTelegramDemoThreads() {
    final now = DateTime.now();

    return [
      // 1. Official AI Guide
      ChatThread(
        id: 'ai_coach',
        title: 'Quest AI Guide',
        subtitle: 'Here is your daily connection briefing and quests...',
        time: 'Just now',
        unread: 1,
        isAiCoach: true,
        isOnline: true,
        isPinned: true,
        userHandle: '@quest_ai',
        aiSuggestions: [
          'Find Flutter developers nearby',
          'Explore local tech quests',
          'Check my XP rank',
          'How do audio stages work?',
        ],
        messages: [
          ChatMessage(
            id: 'ai_1',
            text: 'Welcome to *Quest Messenger*! 🚀\nYour 1:1 Telegram-speed hub for community communication.\n\nAsk me anything or pick a quick suggestion below.',
            isMe: false,
            time: '10:00 AM',
            sentAt: now.subtract(const Duration(hours: 2)),
            status: VMessageStatus.read,
          ),
          ChatMessage(
            id: 'ai_2',
            text: '💡 *Pro Tip*: You can swipe any message right to quote-reply, long-press to add emoji reactions, or use the search bar above with real-time character highlighting!',
            isMe: false,
            time: '10:02 AM',
            sentAt: now.subtract(const Duration(hours: 1, minutes: 58)),
            status: VMessageStatus.read,
          ),
        ],
      ),

      // 2. Direct 1:1 Chat - Alex Rivera
      ChatThread(
        id: 'alex_rivera',
        title: 'Alex Rivera',
        subtitle: 'Looks super slick! 🚀 Can\'t wait.',
        time: '11:28 AM',
        unread: 0,
        isOnline: true,
        lastSeenText: 'online',
        userHandle: '@arivera',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        messages: [
          ChatMessage(
            id: 'alex_1',
            text: 'Hey! Are you still joining the Flutter hackathon this Saturday?',
            isMe: false,
            time: '11:15 AM',
            sentAt: now.subtract(const Duration(minutes: 30)),
            status: VMessageStatus.read,
          ),
          ChatMessage(
            id: 'alex_2',
            text: 'Yes! Just finalized the project submission architecture.',
            isMe: true,
            time: '11:18 AM',
            sentAt: now.subtract(const Duration(minutes: 27)),
            status: VMessageStatus.read,
          ),
          ChatMessage(
            id: 'alex_3',
            text: 'Awesome! Listen to the voice note I recorded for our presentation flow:',
            isMe: false,
            time: '11:20 AM',
            sentAt: now.subtract(const Duration(minutes: 25)),
            status: VMessageStatus.read,
          ),
          ChatMessage(
            id: 'alex_4',
            text: 'Voice note (0:14)',
            isMe: false,
            time: '11:21 AM',
            type: MessageType.voiceNote,
            voiceDurationSeconds: 14,
            audioDuration: '0:14',
            sentAt: now.subtract(const Duration(minutes: 24)),
            status: VMessageStatus.read,
          ),
          ChatMessage(
            id: 'alex_5',
            text: 'Love this direction! Here is the mockup I just drafted for the live stage:',
            isMe: true,
            time: '11:24 AM',
            sentAt: now.subtract(const Duration(minutes: 20)),
            status: VMessageStatus.read,
          ),
          ChatMessage(
            id: 'alex_6',
            text: 'New Telegram styled UI components ✨',
            mediaUrl: 'https://images.unsplash.com/photo-1551650975-87deedd944c3?auto=format&fit=crop&w=800&q=80',
            type: MessageType.image,
            isMe: true,
            time: '11:25 AM',
            sentAt: now.subtract(const Duration(minutes: 19)),
            status: VMessageStatus.read,
          ),
          ChatMessage(
            id: 'alex_7',
            text: 'Looks super slick! 🚀 Can\'t wait.',
            isMe: false,
            time: '11:28 AM',
            sentAt: now.subtract(const Duration(minutes: 15)),
            status: VMessageStatus.read,
            reactions: const [
              VBubbleReaction(emoji: '🔥', count: 2, isSelected: true),
              VBubbleReaction(emoji: '👏', count: 1),
            ],
          ),
        ],
      ),

      // 3. Supergroup - Flutter Architecture Global
      ChatThread(
        id: 'flutter_devs',
        title: 'Flutter Architecture Global',
        subtitle: 'David K.: Here you go: https://quest.app/design',
        time: '09:40 AM',
        unread: 3,
        isGroup: true,
        memberCount: 2410,
        pinnedMessageText: 'Weekly Stage Session: Building 1:1 Telegram Interfaces today at 3 PM UTC',
        messages: [
          ChatMessage(
            id: 'fg_1',
            text: 'Good morning everyone! ☀️ Reminder that our weekly live stage session kicks off at 3 PM UTC.',
            senderName: 'Marcus Vance',
            isMe: false,
            time: '09:10 AM',
            sentAt: now.subtract(const Duration(hours: 3)),
            isPinned: true,
          ),
          ChatMessage(
            id: 'fg_2',
            text: 'Will we be discussing local offline caching with Hive and real-time state?',
            senderName: 'Sarah Chen',
            isMe: false,
            time: '09:14 AM',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 55)),
          ),
          ChatMessage(
            id: 'fg_3',
            text: 'Vote on the primary architecture topic for today:',
            senderName: 'Marcus Vance',
            isMe: false,
            time: '09:20 AM',
            type: MessageType.poll,
            sentAt: now.subtract(const Duration(hours: 2, minutes: 45)),
            pollData: const VPollData(
              question: 'Which architecture deep-dive should we prioritize today?',
              options: [
                VPollOption(id: 'p1', text: 'Riverpod 3.0 StreamNotifiers', voteCount: 68, percentage: 52.0),
                VPollOption(id: 'p2', text: 'v_chat_bubbles Telegram UI Engine', voteCount: 42, percentage: 32.0),
                VPollOption(id: 'p3', text: 'Supabase Offline-First Outbox', voteCount: 21, percentage: 16.0),
              ],
              totalVotes: 131,
              hasVoted: true,
              mode: VPollMode.single,
            ),
          ),
          ChatMessage(
            id: 'fg_4',
            text: 'Can someone share the link to the design tokens?',
            senderName: 'David K.',
            isMe: false,
            time: '09:35 AM',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 25)),
          ),
          ChatMessage(
            id: 'fg_5',
            text: 'Here you go: https://quest.app/design - check the color tokens and typography guide.',
            isMe: true,
            time: '09:40 AM',
            sentAt: now.subtract(const Duration(hours: 2, minutes: 20)),
            status: VMessageStatus.read,
            replyTo: const VReplyData(
              originalMessageId: 'fg_4',
              senderId: 'david_k',
              senderName: 'David K.',
              previewText: 'Can someone share the link to the design tokens?',
            ),
            reactions: const [
              VBubbleReaction(emoji: '❤️', count: 4, isSelected: true),
              VBubbleReaction(emoji: '🚀', count: 2),
            ],
          ),
        ],
      ),

      // 4. Direct Chat - Elena Rostova
      ChatThread(
        id: 'elena_r',
        title: 'Elena Rostova',
        subtitle: 'Thanks Elena, reviewing the specs now!',
        time: 'Yesterday',
        unread: 0,
        isOnline: false,
        lastSeenText: 'last seen 15m ago',
        userHandle: '@elena_r',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
        messages: [
          ChatMessage(
            id: 'el_1',
            text: 'Hi! Attached the updated system architecture documentation and export files for review:',
            isMe: false,
            time: 'Yesterday',
            sentAt: now.subtract(const Duration(days: 1, hours: 2)),
          ),
          ChatMessage(
            id: 'el_2',
            text: 'Quest_Platform_Specs_v2.pdf',
            fileName: 'Quest_Platform_Specs_v2.pdf',
            fileSize: 2457600,
            type: MessageType.file,
            isMe: false,
            time: 'Yesterday',
            sentAt: now.subtract(const Duration(days: 1, hours: 1, minutes: 58)),
          ),
          ChatMessage(
            id: 'el_3',
            text: 'Thanks Elena, reviewing the specs now!',
            isMe: true,
            time: 'Yesterday',
            sentAt: now.subtract(const Duration(days: 1, hours: 1)),
            status: VMessageStatus.read,
          ),
        ],
      ),

      // 5. Broadcast Channel - Quest Announcements
      ChatThread(
        id: 'quest_announcements',
        title: 'Quest Announcements',
        subtitle: '🎉 Quest 2.0 is officially live with Telegram Replica Chat!',
        time: 'Sep 12',
        unread: 0,
        isChannel: true,
        memberCount: 18500,
        pinnedMessageText: 'Quest 2.0 Telegram Experience is now available across all platforms',
        messages: [
          ChatMessage(
            id: 'qa_1',
            text: '🎉 *Quest 2.0 is officially live!*\n\nWe have completely revamped our communication layer into a 1:1 Telegram replica experience.\n\n✨ *Key Features*:\n- Native Telegram bubble tails & dynamic grouping\n- High fidelity voice notes with waveforms\n- Interactive polls & emoji reactions\n- In-chat search with keyword highlighting\n\nEnjoy the update!',
            isMe: false,
            time: 'Sep 12',
            sentAt: now.subtract(const Duration(days: 2)),
            reactions: const [
              VBubbleReaction(emoji: '🎉', count: 142, isSelected: true),
              VBubbleReaction(emoji: '🔥', count: 98),
            ],
          ),
        ],
      ),
    ];
  }

  void _notifyDemoStream() {
    if (_cachedThreads != null) {
      _demoStreamController.add(List.from(_cachedThreads!));
    }
  }

  @override
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
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final newMsg = ChatMessage(
      id: 'msg_${now.millisecondsSinceEpoch}',
      text: text,
      isMe: true,
      time: timeStr,
      sentAt: now,
      type: type,
      status: VMessageStatus.read,
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

    if (_cachedThreads != null) {
      final threadIndex = _cachedThreads!.indexWhere((t) => t.id == threadId);
      if (threadIndex != -1) {
        final thread = _cachedThreads![threadIndex];
        final updatedMessages = List<ChatMessage>.from(thread.messages)..add(newMsg);
        _cachedThreads![threadIndex] = thread.copyWith(
          messages: updatedMessages,
          subtitle: text.isNotEmpty ? text : (type == MessageType.image ? '📷 Photo' : 'Voice note'),
          time: timeStr,
        );
        _notifyDemoStream();
      }
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || threadId.startsWith('ai_coach')) return;

    final tempId = 'pending_${now.millisecondsSinceEpoch}';
    final localMsg = LocalChatMessage(
      messageId: tempId,
      roomId: threadId,
      text: text,
      senderId: userId,
      createdAt: now.toIso8601String(),
      type: type.toString().split('.').last,
      isPending: true,
    );
    await _localDb.chatMessagesBox.put(tempId, localMsg);

    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      try {
        await _supabase.from('chat_messages').insert({
          'roomId': threadId,
          'senderId': userId,
          'text': text,
          'time': now.toIso8601String(),
          'type': type.toString().split('.').last,
        });
        await _localDb.chatMessagesBox.delete(tempId);
      } catch (_) {}
    }
  }

  @override
  Future<void> sendVoiceNote(String threadId) async {
    await sendMessage(
      threadId: threadId,
      text: 'Voice note (0:05)',
      type: MessageType.voiceNote,
      voiceDurationSeconds: 5,
      audioDuration: '0:05',
    );
  }

  @override
  Future<void> markThreadRead(String threadId) async {
    if (_cachedThreads != null) {
      final idx = _cachedThreads!.indexWhere((t) => t.id == threadId);
      if (idx != -1) {
        _cachedThreads![idx] = _cachedThreads![idx].copyWith(unread: 0);
        _notifyDemoStream();
      }
    }
  }

  @override
  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
  }) async {
    if (_cachedThreads != null) {
      final threadIdx = _cachedThreads!.indexWhere((t) => t.id == threadId);
      if (threadIdx != -1) {
        final thread = _cachedThreads![threadIdx];
        final msgIdx = thread.messages.indexWhere((m) => m.id == messageId);
        if (msgIdx != -1) {
          final msg = thread.messages[msgIdx];
          final reactions = List<VBubbleReaction>.from(msg.reactions);
          final existingIdx = reactions.indexWhere((r) => r.emoji == emoji);

          if (existingIdx != -1) {
            final current = reactions[existingIdx];
            if (current.isSelected) {
              if (current.count <= 1) {
                reactions.removeAt(existingIdx);
              } else {
                reactions[existingIdx] = VBubbleReaction(
                  emoji: emoji,
                  count: current.count - 1,
                  isSelected: false,
                );
              }
            } else {
              reactions[existingIdx] = VBubbleReaction(
                emoji: emoji,
                count: current.count + 1,
                isSelected: true,
              );
            }
          } else {
            reactions.add(VBubbleReaction(emoji: emoji, count: 1, isSelected: true));
          }

          final updatedMessages = List<ChatMessage>.from(thread.messages);
          updatedMessages[msgIdx] = msg.copyWith(reactions: reactions);
          _cachedThreads![threadIdx] = thread.copyWith(messages: updatedMessages);
          _notifyDemoStream();
        }
      }
    }
  }

  @override
  Future<void> votePoll({
    required String threadId,
    required String messageId,
    required String optionId,
  }) async {
    if (_cachedThreads != null) {
      final threadIdx = _cachedThreads!.indexWhere((t) => t.id == threadId);
      if (threadIdx != -1) {
        final thread = _cachedThreads![threadIdx];
        final msgIdx = thread.messages.indexWhere((m) => m.id == messageId);
        if (msgIdx != -1) {
          final msg = thread.messages[msgIdx];
          final poll = msg.pollData;
          if (poll != null && !poll.hasVoted) {
            final newTotal = poll.totalVotes + 1;
            final updatedOptions = poll.options.map((opt) {
              final isTarget = opt.id == optionId;
              final newCount = isTarget ? opt.voteCount + 1 : opt.voteCount;
              final newPct = ((newCount / newTotal) * 100).toDouble();
              return VPollOption(
                id: opt.id,
                text: opt.text,
                voteCount: newCount,
                percentage: newPct,
              );
            }).toList();

            final updatedPoll = VPollData(
              question: poll.question,
              options: updatedOptions,
              totalVotes: newTotal,
              hasVoted: true,
              mode: poll.mode,
            );

            final updatedMessages = List<ChatMessage>.from(thread.messages);
            updatedMessages[msgIdx] = msg.copyWith(pollData: updatedPoll);
            _cachedThreads![threadIdx] = thread.copyWith(messages: updatedMessages);
            _notifyDemoStream();
          }
        }
      }
    }
  }

  @override
  Future<void> pinMessage({
    required String threadId,
    required String messageId,
  }) async {
    if (_cachedThreads != null) {
      final threadIdx = _cachedThreads!.indexWhere((t) => t.id == threadId);
      if (threadIdx != -1) {
        final thread = _cachedThreads![threadIdx];
        final msg = thread.messages.firstWhere((m) => m.id == messageId);
        _cachedThreads![threadIdx] = thread.copyWith(
          pinnedMessageText: msg.text,
        );
        _notifyDemoStream();
      }
    }
  }

  @override
  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  }) async {
    if (_cachedThreads != null) {
      final threadIdx = _cachedThreads!.indexWhere((t) => t.id == threadId);
      if (threadIdx != -1) {
        final thread = _cachedThreads![threadIdx];
        final updatedMessages = thread.messages.where((m) => m.id != messageId).toList();
        _cachedThreads![threadIdx] = thread.copyWith(messages: updatedMessages);
        _notifyDemoStream();
      }
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return SupabaseChatRepository(Supabase.instance.client, networkInfo, localDb);
});
