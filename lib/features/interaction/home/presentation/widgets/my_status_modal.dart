import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/home/data/stories_provider.dart';
import 'story_viewer_modal.dart';

class MyStatusModal extends ConsumerWidget {
  final List<StoryItem> myStories;

  const MyStatusModal({
    super.key,
    required this.myStories,
  });

  static void show(BuildContext context, {required List<StoryItem> myStories}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MyStatusModal(myStories: myStories),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch storiesProvider so any deletions or additions dynamically update this modal
    final allStories = ref.watch(storiesProvider).value ?? [];
    final activeMyStories = allStories.where((s) =>
        s.isMe ||
        s.communityName == 'My Story' ||
        s.authorName == 'You'
    ).toList();

    // If all stories were deleted while modal is open, auto pop
    if (activeMyStories.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const SizedBox.shrink();
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'add_status_fab',
          backgroundColor: context.colors.questBlue,
          elevation: 4,
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
            context.push('/create');
          },
          child: const Icon(Icons.camera_alt, color: Colors.white),
        ),
        body: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Status',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${activeMyStories.length} ${activeMyStories.length == 1 ? "update" : "updates"} • Disappear after 24h',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add Status',
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colors.questBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: context.colors.questBlue, size: 20),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      context.push('/create');
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: context.colors.border, height: 1),

            // Status Items List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: activeMyStories.length,
                separatorBuilder: (_, _) => Divider(
                  color: context.colors.border.withValues(alpha: 0.4),
                  height: 1,
                  indent: 76,
                ),
                itemBuilder: (context, index) {
                  final story = activeMyStories[index];
                  final hasVideo = (story.muxPlaybackId != null && story.muxPlaybackId!.isNotEmpty) ||
                      (story.videoUrl != null && story.videoUrl!.isNotEmpty);
                  final hasImage = story.content != null && story.content!.startsWith('http');

                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      StoryViewerModal.show(
                        context,
                        customStories: activeMyStories,
                        initialIndex: index,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          // Thumbnail Preview
                          Stack(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.colors.questBlue.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                  color: context.colors.surface,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildThumbnail(story, hasVideo, hasImage, context),
                              ),
                              if (hasVideo)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Status Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story.formattedTimeAgo,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (story.caption.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    story.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 14,
                                      color: context.colors.textMuted,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${story.viewsCount} views',
                                      style: TextStyle(
                                        color: context.colors.textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Popup Actions
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: context.colors.textMuted,
                            ),
                            color: context.colors.card,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.colors.border),
                            ),
                            onSelected: (value) async {
                              if (value == 'view') {
                                HapticFeedback.selectionClick();
                                StoryViewerModal.show(
                                  context,
                                  customStories: activeMyStories,
                                  initialIndex: index,
                                );
                              } else if (value == 'delete') {
                                HapticFeedback.mediumImpact();
                                final confirm = await _showDeleteConfirm(context);
                                if (confirm == true) {
                                  ref.read(storiesProvider.notifier).deleteStory(story.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Status update deleted'),
                                        backgroundColor: context.colors.card,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.play_circle_outline, size: 18, color: context.colors.textPrimary),
                                    const SizedBox(width: 10),
                                    Text('View update', style: TextStyle(color: context.colors.textPrimary)),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: context.colors.crimson),
                                    const SizedBox(width: 10),
                                    Text('Delete update', style: TextStyle(color: context.colors.crimson)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(StoryItem story, bool hasVideo, bool hasImage, BuildContext context) {
    if (hasVideo && story.muxPlaybackId != null && story.muxPlaybackId!.isNotEmpty) {
      return Image.network(
        'https://image.mux.com/${story.muxPlaybackId}/thumbnail.jpg',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: context.colors.surface,
          child: Icon(Icons.video_library, color: context.colors.questBlue, size: 28),
        ),
      );
    } else if (hasImage) {
      return Image.network(
        story.content!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: context.colors.surface,
          child: Icon(Icons.image, color: context.colors.questBlue, size: 28),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              story.ringColor,
              context.colors.auroraPurple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            story.icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      );
    }
  }

  Future<bool?> _showDeleteConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.colors.border),
        ),
        title: Text(
          'Delete 1 status update?',
          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This update will be deleted for everyone who can see your status.',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.crimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
