import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final int categoryIndex;

  const MessagesScreen({super.key, required this.categoryIndex});

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
      return const Scaffold(
        backgroundColor: Color(0xFF0E1621),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2AABEE)),
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
      backgroundColor: const Color(0xFF0E1621),

      body: Column(
        children: [
          // Telegram Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF17212B),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: const Color(0xFF2AABEE),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search chats, channels and messages...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white38,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),



          // Chat List
          Expanded(
            child: filteredThreads.isEmpty
                ? const Center(
                    child: Text(
                      'No chats found',
                      style: TextStyle(color: Colors.white38, fontSize: 15),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filteredThreads.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: Color(0xFF17212B),
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

  Widget _chatTile(BuildContext context, ChatThread thread) {
    final isUnread = thread.unreadCount > 0;
    final isAi = thread.isAiGuide;
    final avatarColor = isAi
        ? const Color(0xFF2AABEE)
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
                            ? const Color(0xFF2AABEE)
                            : const Color(0xFF00C853),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0E1621),
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
                            color: Colors.white,
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
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF2AABEE),
                          size: 14,
                        ),
                      ],
                      if (thread.isMuted) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.volume_off_rounded,
                          color: Colors.white38,
                          size: 14,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        thread.time,
                        style: TextStyle(
                          color: isUnread
                              ? const Color(0xFF2AABEE)
                              : Colors.white38,
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
                        const Icon(
                          Icons.done_all,
                          color: Color(0xFF2AABEE),
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
                            color: isUnread ? Colors.white : Colors.white54,
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
                            color: const Color(0xFF2AABEE),
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
                        const Icon(
                          Icons.push_pin,
                          color: Colors.white38,
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
      backgroundColor: const Color(0xFF17212B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.push_pin_outlined,
                  color: Colors.white70,
                ),
                title: Text(
                  thread.isPinned ? 'Unpin from top' : 'Pin to top',
                  style: const TextStyle(color: Colors.white),
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
                leading: const Icon(
                  Icons.volume_off_rounded,
                  color: Colors.white70,
                ),
                title: Text(
                  thread.isMuted ? 'Unmute' : 'Mute notifications',
                  style: const TextStyle(color: Colors.white),
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
                leading: const Icon(
                  Icons.mark_chat_read_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Mark as read',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(chatProvider.notifier).markThreadRead(thread.id);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete chat',
                  style: TextStyle(color: Colors.redAccent),
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
