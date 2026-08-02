import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/quest_button.dart';
import '../../../communities/data/communities_provider.dart';
import '../../../home/data/stories_provider.dart';
import '../../../messaging/data/chat_provider.dart';
import '../../../profile/data/user_provider.dart';

class PostAnnouncementSheet extends ConsumerStatefulWidget {
  const PostAnnouncementSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PostAnnouncementSheet(),
    );
  }

  @override
  ConsumerState<PostAnnouncementSheet> createState() => _PostAnnouncementSheetState();
}

class _PostAnnouncementSheetState extends ConsumerState<PostAnnouncementSheet> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedCommunityId;
  bool _sendPushNotification = true;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.crimson,
          content: Text('Please provide an announcement headline and body.'),
        ),
      );
      return;
    }

    final communitiesState = ref.read(communitiesProvider);
    final targetComm = communitiesState.communities.firstWhere(
      (c) => c.id == (_selectedCommunityId ?? '1'),
      orElse: () => communitiesState.communities.first,
    );

    // Add to stories
    final newStory = StoryItem(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      authorName: targetComm.name,
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      timeAgo: 'Just now',
      title: title,
      content: message,
      gradient: [AppColors.crimson, AppColors.auroraPurple],
    );
    ref.read(storiesProvider.notifier).addStory(newStory);

    // Send broadcast message to community chat
    ref.read(chatProvider.notifier).sendMessage(
          threadId: targetComm.id,
          text: '📢 [ANNOUNCEMENT] $title:\n$message',
        );

    // Add host XP
    ref.read(userProvider.notifier).addXp(50);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emerald,
        content: Text('Announcement broadcasted to ${targetComm.name}! (+50 Host XP)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final communitiesState = ref.watch(communitiesProvider);
    if (_selectedCommunityId == null && communitiesState.communities.isNotEmpty) {
      _selectedCommunityId = communitiesState.communities.first.id;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Row(
              children: [
                Icon(Icons.campaign, color: AppColors.crimson, size: 26),
                SizedBox(width: 10),
                Text(
                  'Broadcast Announcement',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _selectedCommunityId,
              dropdownColor: AppColors.card,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Target Community',
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              items: communitiesState.communities
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCommunityId = v),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Announcement Title / Subject',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _messageController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Announcement Body & Details',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _sendPushNotification,
              title: const Text('Send Instant Push Notification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Alert all community members immediately', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              activeThumbColor: AppColors.crimson,
              onChanged: (val) => setState(() => _sendPushNotification = val),
            ),
            const SizedBox(height: 20),

            QuestButton(
              label: 'Send Broadcast (+50 Host XP)',
              variant: QuestButtonVariant.primary,
              isFullWidth: true,
              icon: Icons.send_rounded,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
