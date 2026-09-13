import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';
import 'package:quest/features/interaction/messaging/presentation/widgets/telegram_wallpaper.dart';
import 'package:quest/features/interaction/messaging/presentation/widgets/voice_note_bubble.dart';

class CustomPayload extends VCustomBubbleData {
  final dynamic payload;
  const CustomPayload(this.payload);

  @override
  String get contentType => 'custom';
}

class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  String _searchQuery = '';
  ChatMessage? _replyingMessage;
  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  @override
  void initState() {
    super.initState();
    // Mark thread as read on entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).markThreadRead(widget.threadId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    VReplyData? replyData;
    if (_replyingMessage != null) {
      replyData = VReplyData(
        originalMessageId: _replyingMessage!.id,
        senderId: _replyingMessage!.isMe ? 'me' : (_replyingMessage!.senderName ?? 'user'),
        senderName: _replyingMessage!.isMe ? 'You' : (_replyingMessage!.senderName ?? 'User'),
        previewText: _replyingMessage!.text,
      );
    }

    ref.read(chatProvider.notifier).sendMessage(
      threadId: widget.threadId,
      text: text,
      replyTo: replyData,
    );

    _textController.clear();
    setState(() {
      _replyingMessage = null;
    });
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
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openAttachmentSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17212B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _attachmentOption(
                      icon: Icons.photo_library_rounded,
                      color: const Color(0xFF2AABEE),
                      label: 'Gallery',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendSampleImage();
                      },
                    ),
                    _attachmentOption(
                      icon: Icons.insert_drive_file_rounded,
                      color: const Color(0xFF33C659),
                      label: 'File',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendSampleFile();
                      },
                    ),
                    _attachmentOption(
                      icon: Icons.poll_rounded,
                      color: const Color(0xFFFF9500),
                      label: 'Poll',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendSamplePoll();
                      },
                    ),
                    _attachmentOption(
                      icon: Icons.location_on_rounded,
                      color: const Color(0xFF007AFF),
                      label: 'Location',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Live location sharing active')),
                        );
                      },
                    ),
                    _attachmentOption(
                      icon: Icons.person_rounded,
                      color: const Color(0xFFAF52DE),
                      label: 'Contact',
                      onTap: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share contact card')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _sendSampleImage() {
    ref.read(chatProvider.notifier).sendMessage(
      threadId: widget.threadId,
      text: 'Shared photo from gallery 📷',
      type: MessageType.image,
      mediaUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=800&q=80',
    );
    _scrollToBottom();
  }

  void _sendSampleFile() {
    ref.read(chatProvider.notifier).sendMessage(
      threadId: widget.threadId,
      text: 'Quest_Release_Notes.pdf',
      type: MessageType.file,
      fileName: 'Quest_Release_Notes.pdf',
      fileSize: 1048576,
    );
    _scrollToBottom();
  }

  void _sendSamplePoll() {
    ref.read(chatProvider.notifier).sendMessage(
      threadId: widget.threadId,
      text: 'Team check-in poll',
      type: MessageType.poll,
      pollData: const VPollData(
        question: 'Ready for today\'s release rollout?',
        options: [
          VPollOption(id: 'opt1', text: 'All green, ready! 🚀', voteCount: 12, percentage: 80.0),
          VPollOption(id: 'opt2', text: 'Finishing tests ⏳', voteCount: 3, percentage: 20.0),
        ],
        totalVotes: 15,
        hasVoted: false,
        mode: VPollMode.single,
      ),
    );
    _scrollToBottom();
  }

  void _showMessageContextMenu(ChatMessage msg) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF17212B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji Quick Reactions Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF242F3D),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['❤️', '👍', '🔥', '😂', '👏', '🚀', '🎉'].map((emoji) {
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(ctx);
                        ref.read(chatProvider.notifier).toggleReaction(
                          threadId: widget.threadId,
                          messageId: msg.id,
                          emoji: emoji,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(emoji, style: const TextStyle(fontSize: 26)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.reply_rounded, color: Color(0xFF2AABEE)),
                title: const Text('Reply', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _replyingMessage = msg;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                title: const Text('Copy Text', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: msg.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.push_pin_outlined, color: Colors.white70),
                title: const Text('Pin Message', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(chatProvider.notifier).pinMessage(
                    threadId: widget.threadId,
                    messageId: msg.id,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message pinned to header')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.white70),
                title: const Text('Select', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _isSelectionMode = true;
                    _selectedMessageIds.add(msg.id);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(chatProvider.notifier).deleteMessage(
                    threadId: widget.threadId,
                    messageId: msg.id,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatStateAsync = ref.watch(chatProvider);
    final chatState = chatStateAsync.value;

    if (chatState == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0E1621),
        appBar: AppBar(
          backgroundColor: const Color(0xFF17212B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF2AABEE)),
        ),
      );
    }

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
    final telegramBlue = const Color(0xFF2AABEE);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1621),
      appBar: _buildTelegramAppBar(thread, isAi, telegramBlue),
      body: TelegramWallpaper(
        isDark: true,
        child: Column(
          children: [
            // Pinned Message Banner (Telegram header pin bar)
            if (thread.pinnedMessageText != null && thread.pinnedMessageText!.isNotEmpty)
              _buildPinnedHeaderBanner(thread.pinnedMessageText!),

            // Messages list with Telegram bubble styling & grouping
            Expanded(
              child: VBubbleScope(
                style: VBubbleStyle.telegram,
                theme: VBubbleTheme.telegramDark(),
                config: const VBubbleConfig(
                  patterns: VPatternConfig.markdown,
                ),
                isSelectionMode: _isSelectionMode,
                selectedIds: _selectedMessageIds,
                callbacks: VBubbleCallbacks(
                  onTap: (messageId) {
                    if (_isSelectionMode) {
                      setState(() {
                        if (_selectedMessageIds.contains(messageId)) {
                          _selectedMessageIds.remove(messageId);
                          if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
                        } else {
                          _selectedMessageIds.add(messageId);
                        }
                      });
                    }
                  },
                  onLongPress: (messageId, position) {
                    final msg = thread.messages.firstWhere(
                      (m) => m.id == messageId,
                      orElse: () => thread.messages.first,
                    );
                    _showMessageContextMenu(msg);
                  },
                  onSwipeReply: (messageId) {
                    HapticFeedback.mediumImpact();
                    final msg = thread.messages.firstWhere(
                      (m) => m.id == messageId,
                      orElse: () => thread.messages.first,
                    );
                    setState(() {
                      _replyingMessage = msg;
                    });
                  },
                  onReactionTap: (messageId, emoji, position) {
                    HapticFeedback.lightImpact();
                    ref.read(chatProvider.notifier).toggleReaction(
                      threadId: widget.threadId,
                      messageId: messageId,
                      emoji: emoji,
                    );
                  },
                  onPollVote: (messageId, optionId) {
                    HapticFeedback.mediumImpact();
                    ref.read(chatProvider.notifier).votePoll(
                      threadId: widget.threadId,
                      messageId: messageId,
                      optionId: optionId,
                    );
                  },
                  onPatternTap: (match) async {
                    if (match.patternId == 'url') {
                      final uri = Uri.tryParse(match.matchedText);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                ),
                child: _buildMessagesListView(thread),
              ),
            ),

            // AI Suggestion Chips (if available)
            if (isAi && thread.aiSuggestions.isNotEmpty)
              _buildAiSuggestionsBar(thread.aiSuggestions),

            // Active Reply Preview Banner
            if (_replyingMessage != null)
              _buildReplyPreviewBanner(),

            // Telegram Input Bar
            _buildTelegramInputBar(isAi, telegramBlue),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTelegramAppBar(ChatThread thread, bool isAi, Color telegramBlue) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: const Color(0xFF17212B),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: telegramBlue,
          decoration: const InputDecoration(
            hintText: 'Search in chat...',
            hintStyle: TextStyle(color: Colors.white54, fontSize: 15),
            border: InputBorder.none,
          ),
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim();
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      );
    }

    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: const Color(0xFF17212B),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            setState(() {
              _isSelectionMode = false;
              _selectedMessageIds.clear();
            });
          },
        ),
        title: Text(
          '${_selectedMessageIds.length} selected',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.forward_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Forward ${_selectedMessageIds.length} messages')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () {
              for (var id in _selectedMessageIds) {
                ref.read(chatProvider.notifier).deleteMessage(
                  threadId: widget.threadId,
                  messageId: id,
                );
              }
              setState(() {
                _isSelectionMode = false;
                _selectedMessageIds.clear();
              });
            },
          ),
        ],
      );
    }

    final avatarColor = isAi ? const Color(0xFF2AABEE) : const Color(0xFF6C5CE7);
    String statusSubtitle = 'online';
    if (isAi) {
      statusSubtitle = 'bot';
    } else if (thread.isGroup) {
      statusSubtitle = '${thread.memberCount ?? 120} members';
    } else if (thread.isChannel) {
      statusSubtitle = '${thread.memberCount ?? 1500} subscribers';
    } else if (!thread.isOnline && thread.lastSeenText != null) {
      statusSubtitle = thread.lastSeenText!;
    }

    return AppBar(
      backgroundColor: const Color(0xFF17212B),
      elevation: 0.5,
      leadingWidth: 40,
      leading: IconButton(
        padding: const EdgeInsets.only(left: 8),
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/connect');
          }
        },
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: avatarColor.withValues(alpha: 0.25),
                backgroundImage: thread.avatarUrl != null ? NetworkImage(thread.avatarUrl!) : null,
                child: thread.avatarUrl == null
                    ? (isAi
                        ? Icon(Icons.auto_awesome, color: avatarColor, size: 20)
                        : Text(
                            thread.name.isNotEmpty ? thread.name[0] : 'Q',
                            style: TextStyle(
                              color: avatarColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ))
                    : null,
              ),
              if (thread.isOnline || isAi)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: isAi ? const Color(0xFF2AABEE) : const Color(0xFF00C853),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF17212B), width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        thread.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAi || thread.isChannel) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Color(0xFF2AABEE), size: 14),
                    ],
                  ],
                ),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    color: (thread.isOnline || isAi) ? const Color(0xFF2AABEE) : Colors.white54,
                    fontSize: 12,
                    fontWeight: (thread.isOnline || isAi) ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Search in chat',
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isSearching = true;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: Colors.white),
          tooltip: 'Audio Call',
          onPressed: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Starting call with ${thread.name}...')),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF17212B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (val) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$val selected')),
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Mute', child: Text('Mute notifications', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'Clear', child: Text('Clear history', style: TextStyle(color: Colors.white))),
            const PopupMenuItem(value: 'Delete', child: Text('Delete chat', style: TextStyle(color: Colors.redAccent))),
          ],
        ),
      ],
    );
  }

  Widget _buildPinnedHeaderBanner(String pinnedText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF17212B),
        border: Border(bottom: BorderSide(color: Colors.black26, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2AABEE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.push_pin, color: Color(0xFF2AABEE), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pinned Message',
                  style: TextStyle(
                    color: Color(0xFF2AABEE),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  pinnedText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesListView(ChatThread thread) {
    final messages = thread.messages;

    // Resolve continuous message grouping (Telegram radius & tail behavior)
    final groupingInfos = messages.map((m) {
      return VMessageGroupingInfo(
        senderId: m.isMe ? 'me' : (m.senderName ?? 'peer'),
        sentAt: m.sentAt ?? DateTime.now(),
      );
    }).toList();

    final positions = VMessageGrouping.resolve(
      groupingInfos,
      timeThreshold: const Duration(minutes: 2),
    );

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final msg = messages[i];
        final groupPos = positions[i];
        final isAi = thread.isAiGuide;

        // Show date chip if first message or different day
        final showDateChip = i == 0;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDateChip)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: VDateChip(date: 'Today'),
              ),
            _buildTelegramBubble(msg, groupPos, isAi),
          ],
        );
      },
    );
  }

  Widget _buildTelegramBubble(
    ChatMessage msg,
    VMessageGroupPosition groupPos,
    bool isAi,
  ) {
    final isMe = msg.isMe;
    final senderName = isMe ? null : (msg.senderName ?? (isAi ? 'Quest AI' : null));
    final senderColor = isAi ? const Color(0xFF2AABEE) : const Color(0xFF6C5CE7);

    // 1. Image message
    if (msg.type == MessageType.image && msg.mediaUrl != null) {
      return VImageBubble(
        messageId: msg.id,
        isMeSender: isMe,
        time: msg.time,
        status: msg.status ?? (isMe ? VMessageStatus.read : VMessageStatus.sent),
        groupPosition: groupPos,
        senderName: senderName,
        senderColor: senderColor,
        replyTo: msg.replyTo,
        reactions: msg.reactions,
        searchQuery: _searchQuery,
        caption: msg.text.isNotEmpty ? msg.text : null,
        imageFile: VPlatformFile.fromUrl(networkUrl: msg.mediaUrl!),
      );
    }

    // 2. Voice Note message
    if (msg.type == MessageType.voiceNote) {
      return VCustomBubble(
        messageId: msg.id,
        isMeSender: isMe,
        time: msg.time,
        groupPosition: groupPos,
        senderName: senderName,
        senderColor: senderColor,
        status: msg.status ?? (isMe ? VMessageStatus.read : VMessageStatus.sent),
        replyTo: msg.replyTo,
        reactions: msg.reactions,
        data: CustomPayload(msg),
        builder: (context, data) {
          final m = data.payload as ChatMessage;
          return VoiceNoteBubble(
            durationSeconds: m.voiceDurationSeconds > 0 ? m.voiceDurationSeconds : 10,
            isMe: m.isMe,
          );
        },
      );
    }

    // 3. File attachment message
    if (msg.type == MessageType.file) {
      return VFileBubble(
        messageId: msg.id,
        isMeSender: isMe,
        time: msg.time,
        status: msg.status ?? (isMe ? VMessageStatus.read : VMessageStatus.sent),
        groupPosition: groupPos,
        senderName: senderName,
        senderColor: senderColor,
        replyTo: msg.replyTo,
        reactions: msg.reactions,
        searchQuery: _searchQuery,
        file: VPlatformFile.fromUrl(
          networkUrl: msg.mediaUrl ?? 'https://quest.app/files/${msg.fileName ?? "file.pdf"}',
          fileSize: msg.fileSize ?? 1024000,
        ),
      );
    }

    // 4. Poll message
    if (msg.type == MessageType.poll && msg.pollData != null) {
      return VPollBubble(
        messageId: msg.id,
        isMeSender: isMe,
        time: msg.time,
        groupPosition: groupPos,
        senderName: senderName,
        senderColor: senderColor,
        replyTo: msg.replyTo,
        reactions: msg.reactions,
        searchQuery: _searchQuery,
        pollData: msg.pollData!,
      );
    }

    // 5. Standard Text message
    return VTextBubble(
      messageId: msg.id,
      isMeSender: isMe,
      time: msg.time,
      text: msg.text,
      status: msg.status ?? (isMe ? VMessageStatus.read : VMessageStatus.sent),
      groupPosition: groupPos,
      senderName: senderName,
      senderColor: senderColor,
      replyTo: msg.replyTo,
      reactions: msg.reactions,
      searchQuery: _searchQuery,
      linkPreview: msg.linkTargetRoute != null
          ? VLinkPreviewData(
              url: msg.linkTargetRoute!,
              title: msg.linkTitle ?? 'Explore Quest',
              description: msg.linkSubtitle ?? 'Discover community quests',
              layout: VLinkPreviewLayout.sideMedia,
            )
          : null,
    );
  }

  Widget _buildAiSuggestionsBar(List<String> suggestions) {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final prompt = suggestions[i];
          return GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ref.read(chatProvider.notifier).sendMessage(
                threadId: widget.threadId,
                text: prompt,
              );
              _scrollToBottom();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF17212B),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2AABEE).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFF2AABEE), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    prompt,
                    style: const TextStyle(
                      color: Color(0xFF2AABEE),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReplyPreviewBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF17212B),
        border: Border(top: BorderSide(color: Colors.black26)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2AABEE),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reply to ${_replyingMessage!.isMe ? "You" : (_replyingMessage!.senderName ?? "User")}',
                  style: const TextStyle(
                    color: Color(0xFF2AABEE),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _replyingMessage!.text,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            onPressed: () {
              setState(() {
                _replyingMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTelegramInputBar(bool isAi, Color telegramBlue) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        6,
        8,
        MediaQuery.of(context).padding.bottom + 6,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF17212B),
        border: Border(top: BorderSide(color: Colors.black26)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Emoji / Sticker Button
          IconButton(
            icon: const Icon(Icons.sentiment_satisfied_alt_outlined, color: Colors.white60),
            tooltip: 'Emoji & stickers',
            onPressed: () {
              HapticFeedback.lightImpact();
            },
          ),

          // Message Input Field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFF242F3D),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: isAi ? 'Ask AI Guide...' : 'Message',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Attachment Paperclip Button
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: Colors.white60),
            tooltip: 'Attach media or file',
            onPressed: _openAttachmentSheet,
          ),

          // Mic vs Send Action Button
          _textController.text.trim().isEmpty
              ? IconButton(
                  icon: const Icon(Icons.mic, color: Colors.white60),
                  tooltip: 'Record voice note',
                  onPressed: _sendVoiceNote,
                )
              : Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: telegramBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                    tooltip: 'Send',
                    onPressed: _sendMessage,
                  ),
                ),
        ],
      ),
    );
  }
}
