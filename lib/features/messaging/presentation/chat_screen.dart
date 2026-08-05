import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/chat_provider.dart';
import 'widgets/link_preview_bubble.dart';
import 'widgets/voice_note_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({
    super.key,
    required this.threadId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(chatProvider.notifier).sendMessage(
          threadId: widget.threadId,
          text: text,
        );
    _textController.clear();
    _scrollToBottom();
  }

  void _sendVoiceNote() {
    HapticFeedback.mediumImpact();
    ref.read(chatProvider.notifier).sendVoiceNote(widget.threadId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final thread = chatState.getThreadById(widget.threadId) ??
        ChatThread(
          id: widget.threadId,
          title: 'Discussion',
          subtitle: '',
          time: 'Now',
          unread: 0,
          isAiCoach: false,
          messages: [],
        );

    final isAi = thread.isAiGuide;
    final avatarColor = isAi ? AppColors.skyBlue : AppColors.questBlue;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/messages');
            }
          },
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor.withValues(alpha: 0.2),
                  child: isAi
                      ? Icon(Icons.auto_awesome, color: avatarColor, size: 18)
                      : Text(
                          thread.name.isNotEmpty ? thread.name[0] : 'Q',
                          style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isAi ? AppColors.skyBlue : AppColors.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    isAi ? 'Always online • AI Guide' : 'Active now',
                    style: TextStyle(
                      color: isAi ? AppColors.skyBlue : AppColors.emerald,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surface,
                  content: Text('Chat options for ${thread.name}'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: thread.messages.length,
              itemBuilder: (context, i) {
                final msg = thread.messages[i];
                return _buildMessageBubble(msg, isAi, avatarColor);
              },
            ),
          ),

          // AI Suggestion Chips (if available)
          if (thread.aiSuggestions.isNotEmpty)
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: thread.aiSuggestions.map((prompt) => _quickChip(prompt)).toList(),
              ),
            ),

          // Message input bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic_outlined, color: AppColors.questBlue),
                  tooltip: 'Send voice note',
                  onPressed: _sendVoiceNote,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: isAi ? 'Ask AI Guide anything...' : 'Type a message...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.questBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(String prompt) {
    return GestureDetector(
      onTap: () {
        ref.read(chatProvider.notifier).sendMessage(
              threadId: widget.threadId,
              text: prompt,
            );
        _scrollToBottom();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
        ),
        child: Text(
          prompt,
          style: const TextStyle(color: AppColors.skyBlue, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isAi, Color avatarColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isAi
                    ? Icon(Icons.auto_awesome, color: avatarColor, size: 14)
                    : const Icon(Icons.person, color: Colors.white70, size: 16),
              ),
            ),
          ] else
            const SizedBox(width: 32),
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: msg.type == MessageType.voiceNote
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isMe ? AppColors.questBlue : AppColors.card,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: msg.isMe ? const Radius.circular(4) : const Radius.circular(18),
                      bottomLeft: !msg.isMe ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: msg.isMe ? null : Border.all(color: AppColors.border),
                  ),
                  child: msg.type == MessageType.voiceNote
                      ? VoiceNoteBubble(
                          durationSeconds: msg.voiceDurationSeconds,
                          isMe: msg.isMe,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: msg.isMe ? Colors.white : AppColors.textSecondary,
                                fontSize: 15,
                                height: 1.4,
                              ),
                            ),
                            if (msg.type == MessageType.linkPreview && msg.linkTitle != null)
                              LinkPreviewBubble(
                                title: msg.linkTitle!,
                                url: msg.linkUrl,
                                description: msg.linkDescription,
                                isMe: msg.isMe,
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                    if (msg.isMe) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.done_all,
                        size: 13,
                        color: AppColors.skyBlue,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (msg.isMe) const SizedBox(width: 32) else const SizedBox(width: 32),
        ],
      ),
    );
  }
}
