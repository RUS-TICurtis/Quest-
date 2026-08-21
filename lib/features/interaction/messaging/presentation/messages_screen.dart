import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final chatStateAsync = ref.watch(chatProvider);
    final chatState = chatStateAsync.value;

    if (chatState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.questBlue),
        ),
      );
    }

    final filteredThreads = chatState.threads.where((t) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.lastMessage.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.questBlue,
        child: Icon(Icons.edit_square, color: context.colors.textPrimary),
        onPressed: () {
          HapticFeedback.lightImpact();
          context.push('/connect/ai_coach');
        },
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              style: TextStyle(color: context.colors.textPrimary),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search messages and discussions...',
                prefixIcon: Icon(
                  Icons.search,
                  color: context.colors.textMuted,
                ),
                filled: true,
                fillColor: context.colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          SizedBox(height: 8),

          Expanded(
            child: filteredThreads.isEmpty
                ? Center(
                    child: Text(
                      'No messages found',
                      style: TextStyle(color: context.colors.textMuted),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredThreads.length,
                    separatorBuilder: (_, _) => SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final thread = filteredThreads[i];
                      return _chatTile(context, thread);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chatTile(BuildContext context, ChatThread thread) {
    final isUnread = thread.unreadCount > 0;
    final isAi = thread.isAiGuide;
    final avatarColor = isAi ? context.colors.skyBlue : context.colors.questBlue;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/connect/${thread.id}');
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: avatarColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: isAi
                        ? Border.all(
                            color: avatarColor.withValues(alpha: 0.6),
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Center(
                    child: isAi
                        ? Icon(Icons.auto_awesome, color: avatarColor, size: 26)
                        : Text(
                            thread.name.isNotEmpty ? thread.name[0] : 'Q',
                            style: TextStyle(
                              color: avatarColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: isAi ? context.colors.skyBlue : context.colors.emerald,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.colors.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 16),

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
                          thread.name,
                          style: TextStyle(
                            color: isAi ? avatarColor : context.colors.textPrimary,
                            fontSize: 16,
                            fontWeight: isUnread
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        thread.time,
                        style: TextStyle(
                          color: isUnread
                              ? context.colors.questBlue
                              : context.colors.textMuted,
                          fontSize: 12,
                          fontWeight: isUnread
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          thread.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread
                                ? context.colors.textPrimary
                                : context.colors.textSecondary,
                            fontSize: 13,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        SizedBox(width: 10),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.questBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${thread.unreadCount}',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
