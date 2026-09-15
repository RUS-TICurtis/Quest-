import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/video/presentation/video_feed.dart';
import 'package:quest/core/video/feed_video_pool.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:quest/features/interaction/feed/data/feed_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final feedController = ref.watch(feedControllerProvider);

    return ValueListenableBuilder<List<CreatorVideo>>(
      valueListenable: feedController.videos,
      builder: (context, videos, child) {
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
                child: Text(
                  'Video unavailable',
                  style: TextStyle(color: Colors.white54),
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
                      Text(
                        video.description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        onTap: () async {
                          // Backend logic to like video
                          try {
                            final supabase = Supabase.instance.client;
                            await supabase.from('video_likes').insert({
                                'video_id': video.id,
                            });
                          } catch (_) {}
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Liked video!')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildActionIcon(
                        Icons.chat_bubble_outline,
                        '${video.commentCount}',
                        onTap: () {
                          // Handle Comments
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Comments coming soon')),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildActionIcon(
                        Icons.share_outlined,
                        'Share',
                        onTap: () async {
                          // Backend logic to share video
                          try {
                            final supabase = Supabase.instance.client;
                            await supabase.rpc('increment_share_count', params: {'vid': video.id});
                          } catch (_) {}
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Sharing...')));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
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
