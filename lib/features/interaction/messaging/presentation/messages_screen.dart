import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final int categoryIndex;

  const MessagesScreen({super.key, this.categoryIndex = 0});

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

    // Category filtering
    final categoryFiltered = chatState.threads.where((t) {
      switch (widget.categoryIndex) {
        case 1: // Direct
          return !t.isGroup && !t.isChannel && !t.isAiCoach;
        case 2: // Groups
          return t.isGroup;
        case 3: // Channels
          return t.isChannel;
        case 4: // Bots
          return t.isAiCoach;
        case 0: // All
        default:
          return true;
      }
    }).toList();

    // Search filtering
    final filteredThreads = categoryFiltered.where((t) {
      final q = _searchQuery.toLowerCase();
      if (q.isEmpty) return true;
      return t.name.toLowerCase().contains(q) ||
          t.lastMessage.toLowerCase().contains(q);
    }).toList();

    // Sort: pinned first, then by time
    filteredThreads.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.border),
              ),
              child: TextField(
                style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
                cursorColor: context.colors.questBlue,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search chats, channels and messages...',
                  hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 13),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.colors.textMuted,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          // Chat List or Baseline Empty State
          Expanded(
            child: filteredThreads.isEmpty
                ? _buildEmptyState(context)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredThreads.length,
                    separatorBuilder: (_, _) => Divider(
                      color: context.colors.border,
                      height: 1,
                      indent: 74,
                    ),
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

  Widget _buildEmptyState(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: context.colors.questBlue.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.chat_bubble_outline_rounded,
                size: 36,
                color: context.colors.questBlue,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No Matching Conversations' : 'No Conversations Yet',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try searching with a different term or username.'
                  : 'Connect with local builders, join active communities, or scan the radar to initiate direct connections.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (!isSearching)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.questBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push('/connect/user_discovery');
                },
                icon: const Icon(Icons.person_search_rounded, size: 18),
                label: const Text(
                  'Find People',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chatTile(BuildContext context, ChatThread thread) {
    final isUnread = thread.unreadCount > 0;
    final isAi = thread.isAiGuide;
    final avatarColor = isAi
        ? context.colors.questBlue
        : const Color(0xFF6C5CE7);

    // Determine if last message was sent by me
    final lastMsg = thread.messages.isNotEmpty ? thread.messages.last : null;
    final isOutgoing = lastMsg?.isMe ?? false;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/connect/${thread.id}');
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showThreadOptions(context, thread);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Circular Avatar with online pip
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: avatarColor.withValues(alpha: 0.2),
                  backgroundImage: thread.avatarUrl != null
                      ? NetworkImage(thread.avatarUrl!)
                      : null,
                  child: thread.avatarUrl == null
                      ? (isAi
                            ? Icon(
                                Icons.auto_awesome,
                                color: avatarColor,
                                size: 24,
                              )
                            : Text(
                                thread.name.isNotEmpty ? thread.name[0] : 'Q',
                                style: TextStyle(
                                  color: avatarColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ))
                      : null,
                ),
                if (thread.isOnline || isAi)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: isAi
                            ? context.colors.questBlue
                            : const Color(0xFF00C853),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.colors.background,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Name + Status Badges + Timestamp
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          thread.name,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 15.5,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAi || thread.isChannel) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.verified,
                          color: context.colors.questBlue,
                          size: 14,
                        ),
                      ],
                      if (thread.isMuted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.volume_off_rounded,
                          color: context.colors.textMuted,
                          size: 14,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        thread.time,
                        style: TextStyle(
                          color: isUnread
                              ? context.colors.questBlue
                              : context.colors.textMuted,
                          fontSize: 12,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Row 2: Status Checkmarks + Message Snippet + Unread Badge / Pin Icon
                  Row(
                    children: [
                      if (isOutgoing) ...[
                        Icon(
                          Icons.done_all,
                          color: context.colors.questBlue,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          thread.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnread
                                ? context.colors.textPrimary
                                : context.colors.textMuted,
                            fontSize: 13.5,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.questBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else if (thread.isPinned) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.push_pin,
                          color: context.colors.textMuted,
                          size: 16,
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

  void _showThreadOptions(BuildContext context, ChatThread thread) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.push_pin_outlined,
                  color: context.colors.textPrimary,
                ),
                title: Text(
                  thread.isPinned ? 'Unpin from top' : 'Pin to top',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${thread.name} pinned status updated'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.volume_off_rounded,
                  color: context.colors.textPrimary,
                ),
                title: Text(
                  thread.isMuted ? 'Unmute' : 'Mute notifications',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notifications for ${thread.name} toggled'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.mark_chat_read_outlined,
                  color: context.colors.textPrimary,
                ),
                title: Text(
                  'Mark as read',
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(chatProvider.notifier).markThreadRead(thread.id);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: context.colors.crimson,
                ),
                title: Text(
                  'Delete chat',
                  style: TextStyle(color: context.colors.crimson),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${thread.name} deleted')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
