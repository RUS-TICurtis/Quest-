import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/video/feed_video_pool.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class VideoFeed<T> extends ConsumerStatefulWidget {
  final List<T> items;
  final String? Function(T item) urlBuilder;
  final Widget Function(BuildContext context, T item, int index) overlayBuilder;
  final Widget Function(BuildContext context, T item, int index)? fallbackBuilder;
  final Axis scrollDirection;
  final void Function(int index)? onPageChanged;
  final int initialIndex;
  final bool isLoadingMore;
  final NotifierProvider<FeedVideoPool, void> poolProvider;

  const VideoFeed({
    super.key,
    required this.items,
    required this.urlBuilder,
    required this.overlayBuilder,
    this.fallbackBuilder,
    this.scrollDirection = Axis.vertical,
    this.onPageChanged,
    this.initialIndex = 0,
    this.isLoadingMore = false,
    required this.poolProvider,
  });

  @override
  ConsumerState<VideoFeed<T>> createState() => _VideoFeedState<T>();
}

class _VideoFeedState<T> extends ConsumerState<VideoFeed<T>> {
  late PageController _pageController;
  int _lastSyncedCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pool = ref.watch(widget.poolProvider.notifier);

    // Sync URLs to pool
    if (widget.items.length != _lastSyncedCount && widget.items.isNotEmpty) {
      _lastSyncedCount = widget.items.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final urls = widget.items.map((e) {
            final url = widget.urlBuilder(e);
            return url ?? '';
          }).toList();
          pool.setVideos(urls);
        }
      });
    }

    final itemCount = widget.items.length;

    if (itemCount == 0) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.questBlue),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: VisibilityDetector(
        key: const Key('video-feed-visibility'),
        onVisibilityChanged: (info) {
          pool.setGlobalPause(info.visibleFraction == 0);
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: widget.scrollDirection,
          itemCount: itemCount,
          onPageChanged: (index) {
            widget.onPageChanged?.call(index);
            pool.onPageChanged(index);
          },
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final url = widget.urlBuilder(item);
            final hasVideo = url != null && url.isNotEmpty;
            final controller = pool.getController(index);
            final isInitialized = pool.isInitialized(index);
            final isError = pool.isError(index);

            return Stack(
              fit: StackFit.expand,
              children: [
                if (!hasVideo || isError)
                  if (widget.fallbackBuilder != null)
                    widget.fallbackBuilder!(context, item, index)
                  else
                    Container(color: Colors.black)
                else if (controller != null && isInitialized)
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
                    child: CircularProgressIndicator(
                      color: context.colors.questBlue,
                    ),
                  ),

                // Overlay
                widget.overlayBuilder(context, item, index),

                // Pagination Loader
                if (widget.isLoadingMore && index == itemCount - 1)
                  Positioned(
                    bottom: widget.scrollDirection == Axis.vertical ? 16 : null,
                    right: widget.scrollDirection == Axis.horizontal ? 16 : null,
                    left: widget.scrollDirection == Axis.vertical ? 0 : null,
                    top: widget.scrollDirection == Axis.horizontal ? 0 : null,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
