import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/core/video/presentation/video_feed.dart';
import 'package:quest/core/video/feed_video_pool.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:quest/features/interaction/feed/data/feed_provider.dart';
import 'package:quest/features/interaction/feed/data/feed_repository.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/shared/widgets/expandable_caption.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  void _promptSignIn(String actionName) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: context.colors.questBlue,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sign In Required',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Quest to $actionName, follow creators, and earn XP.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.questBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/login');
                    },
                    child: const Text(
                      'Sign In / Create Account',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLike(CreatorVideo video) async {
    final accessLevel = ref.read(authProvider).accessLevel;
    if (accessLevel != AccessLevel.member) {
      _promptSignIn('like experiences');
      return;
    }

    HapticFeedback.lightImpact();
    try {
      await ref.read(feedRepositoryProvider).likeVideo(video.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Liked!'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not like video: $e')),
      );
    }
  }

  void _handleComment(CreatorVideo video) {
    final accessLevel = ref.read(authProvider).accessLevel;
    if (accessLevel != AccessLevel.member) {
      _promptSignIn('comment on videos');
      return;
    }
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comments are coming soon!')),
    );
  }

  void _showShareSheet(CreatorVideo video) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          context.colors.questBlue.withValues(alpha: 0.2),
                      backgroundImage: video.creatorAvatarUrl != null
                          ? NetworkImage(video.creatorAvatarUrl!)
                          : null,
                      child: video.creatorAvatarUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share @${video.creatorUsername ?? "creator"}\'s experience',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (video.description.isNotEmpty)
                            Text(
                              video.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareAction(
                      icon: Icons.link,
                      label: 'Copy Link',
                      onTap: () async {
                        Navigator.pop(ctx);
                        await Clipboard.setData(
                          ClipboardData(
                            text: 'https://qwst.run/experience/${video.id}',
                          ),
                        );
                        HapticFeedback.lightImpact();
                        ref.read(feedRepositoryProvider).shareVideo(video.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('📋 Link copied to clipboard!'),
                            backgroundColor: context.colors.emerald,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _buildShareAction(
                      icon: Icons.chat_bubble_outline,
                      label: 'Send in Chat',
                      onTap: () {
                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                        ref.read(feedRepositoryProvider).shareVideo(video.id);
                        context.push('/connect?tab=messages');
                      },
                    ),
                    _buildShareAction(
                      icon: Icons.groups_outlined,
                      label: 'Guild Post',
                      onTap: () {
                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                        ref.read(feedRepositoryProvider).shareVideo(video.id);
                        context.push('/connect?tab=communities');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.card,
              shape: BoxShape.circle,
              border: Border.all(color: context.colors.border),
            ),
            child: Icon(icon, color: context.colors.textPrimary, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleShare(CreatorVideo video) async {
    final accessLevel = ref.read(authProvider).accessLevel;
    if (accessLevel != AccessLevel.member) {
      _promptSignIn('share experiences');
      return;
    }
    _showShareSheet(video);
  }

  @override
  Widget build(BuildContext context) {
    final feedController = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: ValueListenableBuilder<List<CreatorVideo>>(
        valueListenable: feedController.videos,
        builder: (context, videos, child) {
          if (videos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.videocam_outlined,
                        size: 48,
                        color: context.colors.questBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      // TODO: Implement a more engaging message for the user based on their activity, interests, and profile. make it target them to post something, anything at all, or to complete quests to continue doomscrolling
                      'No Videos in Feed',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first explorer to capture and publish a video experience.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.questBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.push('/create');
                      },
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text(
                        'Create Experience',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return VideoFeed<CreatorVideo>(
            poolProvider: feedVideoPoolProvider,
            items: videos,
            urlBuilder: (video) {
              if (video.muxPlaybackId != null &&
                  video.muxPlaybackId!.isNotEmpty) {
                return 'https://stream.mux.com/${video.muxPlaybackId!}.m3u8';
              }
              return video.videoUrl;
            },
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              feedController.onPageChanged(index);
            },
            isLoadingMore: feedController.isLoadingMore.value,
            fallbackBuilder: (context, video, index) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white54, size: 40),
                      const SizedBox(height: 8),
                      const Text(
                        'Video unavailable',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              );
            },
            overlayBuilder: (context, video, index) {
              return Stack(
                children: [
                  // Creator info overlay
                  Positioned(
                    bottom: 40,
                    left: 20,
                    right: 80,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '@${video.creatorUsername ?? 'creator'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ExpandableCaption(
                          text: video.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),

                  // Right-side action buttons
                  Positioned(
                    bottom: 40,
                    right: 16,
                    child: Column(
                      children: [
                        _buildActionIcon(
                          Icons.favorite_border,
                          '${video.likeCount}',
                          onTap: () => _handleLike(video),
                        ),
                        const SizedBox(height: 16),
                        _buildActionIcon(
                          Icons.chat_bubble_outline,
                          '${video.commentCount}',
                          onTap: () => _handleComment(video),
                        ),
                        const SizedBox(height: 16),
                        _buildActionIcon(
                          Icons.share_outlined,
                          video.shareCount > 0 ? '${video.shareCount}' : 'Share',
                          onTap: () => _handleShare(video),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
