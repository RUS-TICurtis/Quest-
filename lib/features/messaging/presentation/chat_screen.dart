import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'messages_screen.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const ChatMessage({required this.text, required this.isMe, required this.time});
}

class ChatScreen extends StatefulWidget {
  final ChatPreviewModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    const ChatMessage(text: "Hey! Did you see the new event posted in the design channel?", isMe: false, time: "10:30 AM"),
    const ChatMessage(text: "Yeah, the round table one right? Looks super interesting.", isMe: true, time: "10:32 AM"),
    const ChatMessage(text: "Exactly. I'm definitely going. We should catch up before it starts if you're free.", isMe: false, time: "10:33 AM"),
  ];

  @override
  void initState() {
    super.initState();
    // Add AI specific initial messages if applicable
    if (widget.chat.isAi) {
      _messages.clear();
      _messages.add(const ChatMessage(text: "Hey Alex. You mentioned you were looking for Flutter devs to collaborate with. I found 3 people attending the meetup tonight who match that profile. Should I introduce you?", isMe: false, time: "2m ago"));
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text: _textController.text.trim(), isMe: true, time: "Just now"));
      _textController.clear();
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.chat;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: c.avatarColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: c.isAi ? Border.all(color: c.avatarColor.withValues(alpha: 0.5), width: 1.5) : null,
              ),
              child: Center(
                child: c.isAi 
                    ? Icon(Icons.auto_awesome, color: c.avatarColor, size: 18)
                    : Text(c.name[0], style: TextStyle(color: c.avatarColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(c.isOnline ? 'Online' : 'Offline', style: TextStyle(color: c.isOnline ? AppColors.emerald : AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          if (c.isAi)
            IconButton(icon: const Icon(Icons.tune, color: AppColors.textMuted), onPressed: () {})
          else ...[
            IconButton(icon: const Icon(Icons.call_outlined, color: AppColors.textMuted), onPressed: () {}),
            IconButton(icon: const Icon(Icons.info_outline, color: AppColors.textMuted), onPressed: () {}),
          ]
        ],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.only(left: 16, right: 8, top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.textMuted),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: c.isAi ? 'Ask Quest Guide anything...' : 'Message...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.card,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: c.isAi ? c.avatarColor : AppColors.questBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 18),
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

  Widget _buildMessageBubble(ChatMessage msg) {
    final c = widget.chat;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: msg.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: c.avatarColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: c.isAi 
                    ? Icon(Icons.auto_awesome, color: c.avatarColor, size: 14)
                    : Text(c.name[0], style: TextStyle(color: c.avatarColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ] else const SizedBox(width: 36), // Align offset
          
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: msg.isMe ? AppColors.questBlue : AppColors.card,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomRight: msg.isMe ? const Radius.circular(4) : const Radius.circular(18),
                      bottomLeft: !msg.isMe ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                    border: msg.isMe ? null : Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isMe ? Colors.white : AppColors.textSecondary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(msg.time, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          
          if (msg.isMe) const SizedBox(width: 36) else const SizedBox(width: 36),
        ],
      ),
    );
  }
}
