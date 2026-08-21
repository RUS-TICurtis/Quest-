import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quest/core/network/network_info.dart';
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

  SupabaseChatRepository(this._supabase, this._networkInfo);

  @override
  Stream<List<ChatThread>> getThreadsStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value([_mockAiCoachThread()]);
    }

    // Since streaming joined tables is hard, we can stream the messages table
    // and manually fetch the chats metadata.
    // For simplicity, we just stream messages where sender_id == me OR chat_participants contains me.
    // However, since we're using Riverpod, let's stream chats.
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .asyncMap((chatsData) async {
          List<ChatThread> threads = [];
          for (var chatData in chatsData) {
            final chatId = chatData['id'];
            
            // Get messages for this chat
            final messagesData = await _supabase
                .from('messages')
                .select()
                .eq('chat_id', chatId)
                .order('created_at', ascending: false)
                .limit(50);
            
            final messages = messagesData.map((m) {
              return ChatMessage(
                id: m['id'],
                text: m['content'] ?? '',
                isMe: m['sender_id'] == userId,
                time: m['created_at'] != null ? DateTime.parse(m['created_at']).toLocal().toString() : '',
                type: m['type'] == 'text' ? MessageType.text : MessageType.linkPreview,
              );
            }).toList();

            threads.add(
              ChatThread(
                id: chatId,
                title: chatData['group_name'] ?? 'Chat',
                subtitle: chatData['last_message'] ?? '',
                time: chatData['last_message_at'] ?? '',
                unread: 0,
                isAiCoach: false,
                messages: messages.reversed.toList(),
              )
            );
          }
          
          // Always include AI Coach
          threads.insert(0, _mockAiCoachThread());
          
          return threads;
        });
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

    final isOnline = await _networkInfo.isConnected;
    if (isOnline) {
      await _supabase.from('messages').insert({
        'chat_id': threadId,
        'sender_id': userId,
        'content': text,
        'type': type.toString().split('.').last,
      });
      
      await _supabase.from('chats').update({
        'last_message': text,
        'last_message_at': DateTime.now().toIso8601String(),
        'last_message_sender_id': userId,
      }).eq('id', threadId);
    } else {
      // Offline fallback: Send via SMS using url_launcher
      final Uri smsUri = Uri(
        scheme: 'sms',
        queryParameters: <String, String>{'body': text},
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
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
  return SupabaseChatRepository(Supabase.instance.client, networkInfo);
});
