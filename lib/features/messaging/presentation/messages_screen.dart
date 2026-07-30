import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'chat_screen.dart';

class ChatPreviewModel {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isAi;
  final Color avatarColor;

  const ChatPreviewModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.isAi,
    required this.avatarColor,
  });
}

final _mockChats = [
  const ChatPreviewModel(
    id: 'ai_coach',
    name: 'Quest Guide',
    lastMessage: 'I found 3 developers attending the meetup tonight. Should I introduce you?',
    time: '2m',
    unreadCount: 1,
    isOnline: true,
    isAi: true,
    avatarColor: AppColors.skyBlue,
  ),
  const ChatPreviewModel(
    id: '1',
    name: 'Sarah Chen',
    lastMessage: 'Are you going to the Design Systems talk tomorrow?',
    time: '1h',
    unreadCount: 0,
    isOnline: true,
    isAi: false,
    avatarColor: AppColors.auroraPurple,
  ),
  const ChatPreviewModel(
    id: '2',
    name: 'Marcus Johnson',
    lastMessage: 'Thanks for the feedback on the proposal! Let\'s catch up next week.',
    time: '3h',
    unreadCount: 0,
    isOnline: false,
    isAi: false,
    avatarColor: AppColors.questBlue,
  ),
  const ChatPreviewModel(
    id: '3',
    name: 'Flutter Builders (Group)',
    lastMessage: 'David: Just released the new state management library.',
    time: 'Yesterday',
    unreadCount: 12,
    isOnline: false,
    isAi: false,
    avatarColor: AppColors.emerald,
  ),
];

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(icon: const Icon(Icons.edit_square), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          const SizedBox(height: 12),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _mockChats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final chat = _mockChats[i];
                return _chatTile(context, chat);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatTile(BuildContext context, ChatPreviewModel chat) {
    final isUnread = chat.unreadCount > 0;
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat))),
      child: Container(
        color: Colors.transparent, // For gesture detection
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: chat.avatarColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: chat.isAi ? Border.all(color: chat.avatarColor.withValues(alpha: 0.5), width: 1.5) : null,
                  ),
                  child: Center(
                    child: chat.isAi 
                        ? Icon(Icons.auto_awesome, color: chat.avatarColor, size: 28)
                        : Text(chat.name[0], style: TextStyle(color: chat.avatarColor, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                ),
                if (chat.isOnline)
                  Positioned(
                    bottom: 2, right: 2,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(color: AppColors.emerald, shape: BoxShape.circle, border: Border.all(color: AppColors.background, width: 2.5)),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: TextStyle(
                            color: chat.isAi ? chat.avatarColor : Colors.white,
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(chat.time, style: TextStyle(color: isUnread ? AppColors.questBlue : AppColors.textMuted, fontSize: 12, fontWeight: isUnread ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread ? Colors.white : AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.questBlue, borderRadius: BorderRadius.circular(10)),
                          child: Text('${chat.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ]
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
