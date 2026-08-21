import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/video/feed_video_pool.dart';
import 'package:video_player/video_player.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/feed/data/feed_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The FeedController will now handle loading the videos from the provider.
      // We will sync the feedControllerProvider's videos with the feedVideoPool.
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pool = ref.watch(feedVideoPoolProvider.notifier);
    final feedController = ref.watch(feedControllerProvider);
    
    return ValueListenableBuilder<List<CreatorVideo>>(
      valueListenable: feedController.videos,
      builder: (context, videos, child) {
        // Sync with video pool
        if (videos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            pool.setVideos(videos);
          });
        }
        
        final videoCount = videos.length;

        return Scaffold(
          backgroundColor: Colors.black,
          body: VisibilityDetector(
            key: const Key('feed-visibility'),
            onVisibilityChanged: (info) {
              if (info.visibleFraction == 0) {
                pool.setGlobalPause(true);
              } else {
                pool.setGlobalPause(false);
              }
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: videoCount,
              onPageChanged: (index) {
                feedController.onPageChanged(index);
                pool.onPageChanged(index);
              },
              itemBuilder: (context, index) {
                final video = videos[index];
                final controller = pool.getController(index);
                final isInitialized = pool.isInitialized(index);
            
            return Stack(
              fit: StackFit.expand,
              children: [
                if (controller != null && isInitialized)
                  GestureDetector(
                    onTap: () {
                      if (controller.value.isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    },
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: controller.value.size.width,
                        height: controller.value.size.height,
                        child: VideoPlayer(controller),
                      ),
                    ),
                  )
                else
                  Center(
                    child: CircularProgressIndicator(color: context.colors.questBlue),
                  ),
                
                // Overlay text
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
                      Text(
                        video.description,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Right actions (like, comment, share)
                Positioned(
                  bottom: 40,
                  right: 16,
                  child: Column(
                    children: [
                      _buildActionIcon(Icons.favorite_border, '${video.likeCount}'),
                      const SizedBox(height: 16),
                      _buildActionIcon(Icons.chat_bubble_outline, '${video.commentCount}'),
                      const SizedBox(height: 16),
                      _buildActionIcon(Icons.share_outlined, 'Share'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
      }
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
