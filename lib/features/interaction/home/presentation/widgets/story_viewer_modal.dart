import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/features/interaction/home/data/stories_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/core/video/feed_video_pool.dart';
import 'package:video_player/video_player.dart';

class StoryViewerModal extends ConsumerStatefulWidget {
  final int initialIndex;

  const StoryViewerModal({super.key, this.initialIndex = 0});

  static void show(BuildContext context, {int initialIndex = 0}) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Story Viewer',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (context, anim1, anim2) {
        return StoryViewerModal(initialIndex: initialIndex);
      },
    );
  }

  @override
  ConsumerState<StoryViewerModal> createState() => _StoryViewerModalState();
}

class _StoryViewerModalState extends ConsumerState<StoryViewerModal>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _progressController;
  VideoPlayerController? _currentVideoController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController =
        AnimationController(vsync: this, duration: Duration(seconds: 5))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _nextStory();
            }
          });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPool();
      _markCurrentSeen();
      _checkVideoAndPlay();
    });
  }

  void _initPool() {
    final stories = ref.read(storiesProvider).value ?? [];
    final pool = ref.read(storiesVideoPoolProvider.notifier);
    final urls = stories.map((s) {
      if (s.muxPlaybackId != null && s.muxPlaybackId!.isNotEmpty) {
        return 'https://stream.mux.com/${s.muxPlaybackId!}.m3u8';
      }
      return s.videoUrl ?? '';
    }).toList();
    
    // Temporarily overwrite current index logic of pool to match story's index
    // Note: Pool handles its own internal _currentIndex when onPageChanged is called.
    pool.setVideos(urls);
    for (int i = 0; i < _currentIndex; i++) {
      pool.onPageChanged(i); // fast-forward pool index
    }
    pool.onPageChanged(_currentIndex);
  }

  void _checkVideoAndPlay() {
    _currentVideoController?.removeListener(_videoListener);
    final pool = ref.read(storiesVideoPoolProvider.notifier);
    _currentVideoController = pool.getController(_currentIndex);

    if (_currentVideoController != null && pool.isInitialized(_currentIndex)) {
      _progressController.stop();
      _currentVideoController!.addListener(_videoListener);
      _currentVideoController!.play();
    } else if (_currentVideoController != null) {
      // Waiting for init
      _progressController.stop();
      Future.delayed(Duration(milliseconds: 100), () {
        if (mounted) _checkVideoAndPlay();
      });
    } else {
      // No video
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _videoListener() {
    if (_currentVideoController == null) return;
    if (_currentVideoController!.value.isInitialized) {
      final pos = _currentVideoController!.value.position.inMilliseconds;
      final dur = _currentVideoController!.value.duration.inMilliseconds;
      if (dur > 0) {
        setState(() {
          _progressController.value = pos / dur;
        });
        if (pos >= dur && !_currentVideoController!.value.isPlaying) {
          _nextStory();
        }
      }
    }
  }

  void _markCurrentSeen() {
    final stories = ref.read(storiesProvider).value ?? [];
    if (_currentIndex < stories.length) {
      ref
          .read(storiesProvider.notifier)
          .markAsSeen(stories[_currentIndex].id);
    }
  }

  void _nextStory() {
    final stories = ref.read(storiesProvider).value ?? [];
    if (_currentIndex < stories.length - 1) {
      HapticFeedback.selectionClick();
      
      _currentVideoController?.removeListener(_videoListener);
      _currentVideoController?.pause();

      setState(() {
        _currentIndex++;
      });
      
      ref.read(storiesVideoPoolProvider.notifier).onPageChanged(_currentIndex);
      
      _markCurrentSeen();
      _checkVideoAndPlay();
    } else {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      
      _currentVideoController?.removeListener(_videoListener);
      _currentVideoController?.pause();

      setState(() {
        _currentIndex--;
      });
      
      ref.read(storiesVideoPoolProvider.notifier).onPageChanged(_currentIndex);

      _markCurrentSeen();
      _checkVideoAndPlay();
    }
  }

  @override
  void dispose() {
    _currentVideoController?.removeListener(_videoListener);
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider).value ?? [];
    // We watch the pool to rebuild when video initializes
    final pool = ref.watch(storiesVideoPoolProvider.notifier);

    if (stories.isEmpty || _currentIndex >= stories.length) {
      return SizedBox.shrink();
    }
    final story = stories[_currentIndex];
    final hasVideoUrl = (story.muxPlaybackId != null && story.muxPlaybackId!.isNotEmpty) || (story.videoUrl != null && story.videoUrl!.isNotEmpty);
    
    // In build, we can fetch controller directly to render it
    final controller = pool.getController(_currentIndex);
    final isInitialized = pool.isInitialized(_currentIndex);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null &&
                details.primaryVelocity! > 300) {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            }
          },
          onTapDown: (_) {
            _progressController.stop();
            controller?.pause();
          },
          onTapUp: (details) {
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _previousStory();
            } else {
              _nextStory();
            }
          },
          onTapCancel: () {
            if (controller != null && isInitialized) {
              controller.play();
            } else {
              _progressController.forward();
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Layer
              if (hasVideoUrl)
                if (controller != null && isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  )
                else
                  Center(child: CircularProgressIndicator(color: story.ringColor))
              else
                // Fallback Vibrant backdrop gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        story.ringColor.withValues(alpha: 0.35),
                        context.colors.background,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: story.ringColor.withValues(alpha: 0.2),
                              border: Border.all(
                                color: story.ringColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: story.ringColor.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              story.icon,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 32),
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.colors.surface.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: story.ringColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  story.communityName.toUpperCase(),
                                  style: TextStyle(
                                    color: story.ringColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '"${story.caption}"',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Overlay: Video caption
              if (hasVideoUrl && story.caption.isNotEmpty)
                Positioned(
                  bottom: 32,
                  left: 16,
                  right: 16,
                  child: Text(
                    story.caption,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2))
                      ]
                    ),
                  ),
                ),

              // Header & Progress Indicators
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Segmented Progress Bars
                    Row(
                      children: List.generate(stories.length, (index) {
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, child) {
                                double value = 0.0;
                                if (index < _currentIndex) {
                                  value = 1.0;
                                } else if (index == _currentIndex) {
                                  value = _progressController.value;
                                }
                                return LinearProgressIndicator(
                                  value: value,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    story.ringColor,
                                  ),
                                  minHeight: 3,
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 12),

                    // Author info & Close button
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: story.ringColor,
                          child: Text(
                            story.authorName
                                .split(' ')
                                .map((s) => s[0])
                                .take(2)
                                .join(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.authorName,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${story.communityName} • ${story.timeAgo}',
                              style: TextStyle(
                                color: context.colors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
