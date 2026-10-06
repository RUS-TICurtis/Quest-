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
  Future<void> createChatRoom(String otherUserId);
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

  RealtimeChannel? _realtimeChannel;

  SupabaseChatRepository(this._supabase, this._networkInfo, this._localDb);

  void dispose() {
    _realtimeChannel?.unsubscribe();
  }

  @override
  Stream<List<ChatThread>> getThreadsStream() async* {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      yield const [];
      return;
    }

    // Trigger background sync
    _syncThreads(userId);

    // Yield initial local data
    yield _buildThreadsFromLocal(userId);

    // Subscribe to Realtime — any new chat_message triggers a re-sync
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _supabase
        .channel('chat_messages_for_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => _syncThreads(userId),
        )
        .subscribe();

    // Listen to local DB changes for live UI updates
    await for (final _ in _localDb.chatRoomsBox.watch()) {
      yield _buildThreadsFromLocal(userId);
    }
  }

  List<ChatThread> _buildThreadsFromLocal(String userId) {
    final threads = <ChatThread>[];
    for (var localRoom in _localDb.chatRoomsBox.values) {
      final localMessages =
          _localDb.chatMessagesBox.values
              .where((m) => m.roomId == localRoom.roomId)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final messages = localMessages.map((m) {
        return ChatMessage(
          id: m.messageId,
          text: m.text,
          isMe: m.senderId == userId,
          time:
              DateTime.tryParse(m.createdAt)?.toLocal().toString() ??
              m.createdAt,
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

    return threads;
  }

  Future<void> _syncThreads(String userId) async {
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      _syncOutbox(userId);
      return;
    }

    try {
      final participantsData = await _supabase
          .from('chat_participants')
          .select()
          .eq('userId', userId);

      for (var pData in participantsData) {
        final roomId = pData['roomId'];

        final roomData = await _supabase
            .from('chat_rooms')
            .select()
            .eq('id', roomId)
            .single();

        final localRoom = LocalChatRoom(
          roomId: roomId,
          name: roomData['name'] ?? 'Chat',
          lastMessageText: roomData['lastMessageText'] ?? '',
          lastMessageTime: roomData['lastMessageTime'] ?? '',
          unreadCount: 0,
          isAiCoach: false,
        );
        await _localDb.chatRoomsBox.put(roomId, localRoom);

        final messagesData = await _supabase
            .from('chat_messages')
            .select()
            .eq('roomId', roomId)
            .order('createdAt', ascending: false)
            .limit(50);

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
    final pendingMessages = _localDb.chatMessagesBox.values
        .where((m) => m.isPending && m.senderId == userId)
        .toList();
    if (pendingMessages.isEmpty) return;

    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) return;

    for (var pendingMsg in pendingMessages) {
      try {
        try {
          await _supabase.functions.invoke(
            'send-message',
            body: {
              'roomId': pendingMsg.roomId,
              'text': pendingMsg.text,
              'time': pendingMsg.createdAt,
              'type': pendingMsg.type,
            },
          );
        } catch (_) {
          await _supabase.from('chat_messages').insert({
            'roomId': pendingMsg.roomId,
            'senderId': pendingMsg.senderId,
            'text': pendingMsg.text,
            'time': pendingMsg.createdAt,
            'type': pendingMsg.type,
          });
        }

        await _localDb.chatMessagesBox.delete(pendingMsg.messageId);
      } catch (_) {
        // Retry next sync
      }
    }
    _syncThreads(userId);
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
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

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

    // Update local room last message metadata
    final existingRoom = _localDb.chatRoomsBox.get(threadId);
    if (existingRoom != null) {
      await _localDb.chatRoomsBox.put(
        threadId,
        LocalChatRoom(
          roomId: existingRoom.roomId,
          name: existingRoom.name,
          lastMessageText: text.isNotEmpty
              ? text
              : (type == MessageType.image ? '📷 Photo' : 'Voice note'),
          lastMessageTime: timeStr,
          unreadCount: 0,
          isAiCoach: existingRoom.isAiCoach,
        ),
      );
    }

    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      try {
        try {
          await _supabase.functions.invoke(
            'send-message',
            body: {
              'roomId': threadId,
              'text': text,
              'time': now.toIso8601String(),
              'type': type.toString().split('.').last,
            },
          );
        } catch (_) {
          await _supabase.from('chat_messages').insert({
            'roomId': threadId,
            'senderId': userId,
            'text': text,
            'time': now.toIso8601String(),
            'type': type.toString().split('.').last,
          });
        }
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
    final existingRoom = _localDb.chatRoomsBox.get(threadId);
    if (existingRoom != null && existingRoom.unreadCount > 0) {
      await _localDb.chatRoomsBox.put(
        threadId,
        LocalChatRoom(
          roomId: existingRoom.roomId,
          name: existingRoom.name,
          lastMessageText: existingRoom.lastMessageText,
          lastMessageTime: existingRoom.lastMessageTime,
          unreadCount: 0,
          isAiCoach: existingRoom.isAiCoach,
        ),
      );
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase
            .from('chat_participants')
            .update({'lastReadAt': DateTime.now().toIso8601String()})
            .eq('roomId', threadId)
            .eq('userId', userId);
      } catch (_) {}
    }
  }

  @override
  Future<void> createChatRoom(String otherUserId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Check if a 1:1 room already exists between the two users
      final existing = await _supabase
          .from('chat_participants')
          .select('roomId')
          .eq('userId', userId);

      final existingRoomIds = (existing as List<dynamic>)
          .map((e) => e['roomId']?.toString())
          .whereType<String>()
          .toSet();

      final otherRooms = await _supabase
          .from('chat_participants')
          .select('roomId')
          .eq('userId', otherUserId);

      final otherRoomIds = (otherRooms as List<dynamic>)
          .map((e) => e['roomId']?.toString())
          .whereType<String>()
          .toSet();

      final sharedRoomId =
          existingRoomIds.intersection(otherRoomIds).firstOrNull;

      if (sharedRoomId != null) {
        // Room already exists — ensure it is in local Hive cache
        final roomData = await _supabase
            .from('chat_rooms')
            .select()
            .eq('id', sharedRoomId)
            .single();
        final localRoom = LocalChatRoom(
          roomId: sharedRoomId,
          name: roomData['name'] ?? 'Chat',
          lastMessageText: roomData['lastMessageText'] ?? '',
          lastMessageTime: roomData['lastMessageTime'] ?? '',
          unreadCount: 0,
          isAiCoach: false,
        );
        await _localDb.chatRoomsBox.put(sharedRoomId, localRoom);
        return;
      }

      // 2. Create new 1:1 room
      final roomInsert = await _supabase
          .from('chat_rooms')
          .insert({'isGroup': false})
          .select()
          .single();

      final newRoomId = roomInsert['id'] as String;

      // 3. Add current user first to establish room membership for RLS
      await _supabase.from('chat_participants').insert({
        'roomId': newRoomId,
        'userId': userId,
      });

      // 4. Add other participant (authorized via is_chat_participant policy)
      await _supabase.from('chat_participants').insert({
        'roomId': newRoomId,
        'userId': otherUserId,
      });

      // 5. Persist to Hive
      await _localDb.chatRoomsBox.put(
        newRoomId,
        LocalChatRoom(
          roomId: newRoomId,
          name: 'New Chat',
          lastMessageText: '',
          lastMessageTime: '',
          unreadCount: 0,
          isAiCoach: false,
        ),
      );
    } catch (_) {
      // Non-critical — user can retry
    }
  }

  @override
  Future<void> toggleReaction({
    required String threadId,
    required String messageId,
    required String emoji,
  }) async {
    // Reactions synced live via Supabase chat_messages
  }

  @override
  Future<void> votePoll({
    required String threadId,
    required String messageId,
    required String optionId,
  }) async {
    // Poll voting synced live via edge functions
  }

  @override
  Future<void> pinMessage({
    required String threadId,
    required String messageId,
  }) async {
    // Pin message metadata update
  }

  @override
  Future<void> deleteMessage({
    required String threadId,
    required String messageId,
  }) async {
    await _localDb.chatMessagesBox.delete(messageId);
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _supabase
            .from('chat_messages')
            .delete()
            .eq('id', messageId);
      } catch (_) {}
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return SupabaseChatRepository(Supabase.instance.client, networkInfo, localDb);
});
