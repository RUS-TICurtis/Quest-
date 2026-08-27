import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  });
  Future<void> sendVoiceNote(String threadId);
  Future<void> markThreadRead(String threadId);
}

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _supabase;
  final NetworkInfo _networkInfo;
  final LocalDatabaseService _localDb;

  SupabaseChatRepository(this._supabase, this._networkInfo, this._localDb);

  @override
  Stream<List<ChatThread>> getThreadsStream() async* {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      yield [_mockAiCoachThread()];
      return;
    }

    // Trigger background sync
    _syncThreads(userId);

    // Yield initial local data
    yield _buildThreadsFromLocal(userId);

    // Yield anytime a chat room changes
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
          type: MessageType.values.firstWhere(
            (e) => e.toString().split('.').last == m.type,
            orElse: () => MessageType.text,
          ),
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
    threads.insert(0, _mockAiCoachThread());
    threads.sort((a, b) => b.time.compareTo(a.time));
    return threads;
  }

  Future<void> _syncThreads(String userId) async {
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      _syncOutbox(userId); // Try to send pending messages if online check was wrong
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
          // Only overwrite if it's not pending or if it's a real server message
          await _localDb.chatMessagesBox.put(localMsg.messageId, localMsg);
        }
      }

      // After syncing, check if we have any pending messages in outbox to push
      _syncOutbox(userId);
    } catch (e) {
      // Failed to sync
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

        // Delete local pending message, we will fetch the real one on next sync
        await _localDb.chatMessagesBox.delete(pendingMsg.messageId);
      } catch (e) {
        // Still failing, leave as pending
      }
    }
    _syncThreads(userId); // Re-fetch
  }

  ChatThread _mockAiCoachThread() {
    return ChatThread(
      id: 'ai_coach',
      title: 'Quest AI Guide',
      subtitle: 'Here is a recommended connection for you...',
      time: 'Just now',
      unread: 1,
      isAiCoach: true,
      aiSuggestions: [
        'Find events near me',
        'Connect with Flutter developers',
        'How do I earn more XP?',
      ],
      messages: [
        ChatMessage(
          id: 'm1',
          text: 'Hey! 👋 I noticed you\'re exploring mobile architecture.',
          isMe: false,
          time: '10:00 AM',
        ),
      ],
    );
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
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || threadId == 'ai_coach') return;

    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final nowStr = DateTime.now().toIso8601String();

    // 1. Optimistic Update Local Storage (Outbox)
    final localMsg = LocalChatMessage(
      messageId: tempId,
      roomId: threadId,
      text: text,
      senderId: userId,
      createdAt: nowStr,
      type: type.toString().split('.').last,
      isPending: true,
    );
    await _localDb.chatMessagesBox.put(tempId, localMsg);

    // Update Room's last message locally
    final room = _localDb.chatRoomsBox.get(threadId);
    if (room != null) {
      room.lastMessageText = text;
      room.lastMessageTime = nowStr;
      await room.save();
    }

    // 2. Try to sync immediately
    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      try {
        await _supabase.from('chat_messages').insert({
          'roomId': threadId,
          'senderId': userId,
          'text': text,
          'time': nowStr,
          'type': type.toString().split('.').last,
        });

        await _supabase.from('chat_rooms').update({
          'lastMessageText': text,
          'lastMessageTime': nowStr,
        }).eq('id', threadId);

        await _localDb.chatMessagesBox.delete(tempId);
        _syncThreads(userId); // Fetch real message
      } catch (e) {
        // Failed to send online, leave in outbox
      }
    }
  }

  @override
  Future<void> sendVoiceNote(String threadId) async {}

  @override
  Future<void> markThreadRead(String threadId) async {}
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  final localDb = ref.watch(localDatabaseProvider);
  return SupabaseChatRepository(Supabase.instance.client, networkInfo, localDb);
});
