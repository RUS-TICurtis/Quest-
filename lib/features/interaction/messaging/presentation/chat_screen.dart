import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:emoji_extension/emoji_extension.dart' hide Color;
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';
import 'widgets/link_preview_bubble.dart';
import 'widgets/voice_note_bubble.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

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
    var text = _textController.text.trim();
    if (text.isEmpty) return;

    // Parse any typed shortcodes like :grinning: to actual emojis
    text = text.emojis.fromShortcodes();

    HapticFeedback.lightImpact();
    ref
        .read(chatProvider.notifier)
        .sendMessage(threadId: widget.threadId, text: text);
    _textController.clear();
    _scrollToBottom();
  }

  void _sendVoiceNote() {
    HapticFeedback.mediumImpact();
    ref.read(chatProvider.notifier).sendVoiceNote(widget.threadId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatStateAsync = ref.watch(chatProvider);
    final chatState = chatStateAsync.value;

    if (chatState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(color: context.colors.questBlue),
        ),
      );
    }

    final thread =
        chatState.getThreadById(widget.threadId) ??
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
    final avatarColor = isAi ? context.colors.skyBlue : context.colors.questBlue;

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
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
                          style: TextStyle(
                            color: avatarColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isAi ? context.colors.skyBlue : context.colors.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.background,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    isAi ? 'Always online • AI Guide' : 'Active now',
                    style: TextStyle(
                      color: isAi ? context.colors.skyBlue : context.colors.emerald,
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
            icon: Icon(Icons.more_vert),
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: context.colors.surface,
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: thread.aiSuggestions
                    .map((prompt) => _quickChip(prompt))
                    .toList(),
              ),
            ),

          // Message input bar
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(top: BorderSide(color: context.colors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.mic_outlined,
                    color: context.colors.questBlue,
                  ),
                  tooltip: 'Send voice note',
                  onPressed: _sendVoiceNote,
                ),
                SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 15,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: isAi
                          ? 'Ask AI Guide anything...'
                          : 'Type a message...',
                      hintStyle: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 14,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: context.colors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.questBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: context.colors.textPrimary,
                      size: 20,
                    ),
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
        HapticFeedback.lightImpact();
        ref
            .read(chatProvider.notifier)
            .sendMessage(threadId: widget.threadId, text: prompt);
        _scrollToBottom();
      },
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.skyBlue.withValues(alpha: 0.3)),
        ),
        child: Text(
          prompt,
          style: TextStyle(
            color: context.colors.skyBlue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isAi, Color avatarColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: avatarColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isAi
                    ? Icon(Icons.auto_awesome, color: avatarColor, size: 14)
                    : Icon(
                        Icons.person,
                        color: context.colors.textPrimary70,
                        size: 16,
                      ),
              ),
            ),
          ] else
            SizedBox(width: 32),
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final isEmojiOnly =
                        msg.type == MessageType.text && msg.text.emojis.only;

                    return Container(
                      padding: msg.type == MessageType.voiceNote || isEmojiOnly
                          ? EdgeInsets.zero
                          : EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                      decoration: BoxDecoration(
                        color: isEmojiOnly
                            ? Colors.transparent
                            : (msg.isMe ? context.colors.questBlue : context.colors.card),
                        borderRadius: BorderRadius.circular(18).copyWith(
                          bottomRight: msg.isMe
                              ? Radius.circular(4)
                              : Radius.circular(18),
                          bottomLeft: !msg.isMe
                              ? Radius.circular(4)
                              : Radius.circular(18),
                        ),
                        border: msg.isMe || isEmojiOnly
                            ? null
                            : Border.all(color: context.colors.border),
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
                                    color: msg.isMe
                                        ? context.colors.textPrimary
                                        : context.colors.textSecondary,
                                    fontSize:
                                        msg.type == MessageType.text &&
                                            msg.text.emojis.only
                                        ? 40
                                        : 15,
                                    height: 1.4,
                                  ),
                                ),
                                if (msg.type == MessageType.linkPreview &&
                                    msg.linkTitle != null)
                                  LinkPreviewBubble(
                                    title: msg.linkTitle!,
                                    url: msg.linkUrl,
                                    description: msg.linkDescription,
                                    isMe: msg.isMe,
                                  ),
                              ],
                            ),
                    );
                  },
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    if (msg.isMe) ...[
                      SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 13,
                        color: context.colors.skyBlue,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (msg.isMe)
            SizedBox(width: 32)
          else
            SizedBox(width: 32),
        ],
      ),
    );
  }
}
