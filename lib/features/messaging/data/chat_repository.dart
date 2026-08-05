import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/network_info.dart';
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

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _supabase;
  final NetworkInfo _networkInfo;

  SupabaseChatRepository(this._supabase, this._networkInfo);

  @override
  Future<List<ChatThread>> getThreads() async {
    // For now returning mock threads because chat_threads table isn't fully defined
    return [
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
            text: 'Hey! 👋 I noticed you\'re exploring mobile architecture.',
            isMe: false,
            time: '10:00 AM',
          ),
        ],
      ),
    ];
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
    final isOnline = await _networkInfo.isConnected;

    final messageData = {
      'text': text,
      'isMe': true,
      'time': DateTime.now().toIso8601String(),
      'type': type.toString().split('.').last,
      'voiceDurationSeconds': voiceDurationSeconds,
      'audioDuration': audioDuration,
      'waveform': waveform,
      'linkTitle': linkTitle,
      'linkSubtitle': linkSubtitle,
      'linkTargetRoute': linkTargetRoute,
    };

    if (isOnline) {
      // Send via Supabase
      await _supabase.from('chat_messages').insert(messageData);
    } else {
      // Offline fallback: Send via SMS using url_launcher
      final Uri smsUri = Uri(
        scheme: 'sms',
        queryParameters: <String, String>{
          'body': text,
        },
      );
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      }
    }

    // Return the updated thread (mock behavior for UI updates)
    final threads = await getThreads();
    return threads.first;
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
