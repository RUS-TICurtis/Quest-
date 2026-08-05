import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/stories_provider.dart';

class StoryViewerModal extends ConsumerStatefulWidget {
  final int initialIndex;

  const StoryViewerModal({
    super.key,
    this.initialIndex = 0,
  });

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextStory();
        }
      });

    _markCurrentSeen();
    _progressController.forward();
  }

  void _markCurrentSeen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final stories = ref.read(storiesProvider);
      if (_currentIndex < stories.length) {
        ref.read(storiesProvider.notifier).markAsSeen(stories[_currentIndex].id);
      }
    });
  }

  void _nextStory() {
    final stories = ref.read(storiesProvider);
    if (_currentIndex < stories.length - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
      });
      _markCurrentSeen();
      _progressController.reset();
      _progressController.forward();
    } else {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex--;
      });
      _markCurrentSeen();
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(storiesProvider);
    if (stories.isEmpty || _currentIndex >= stories.length) {
      return const SizedBox.shrink();
    }
    final story = stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            }
          },
          onTapDown: (_) => _progressController.stop(),
          onTapUp: (details) {
            _progressController.forward();
            final screenWidth = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < screenWidth / 3) {
              _previousStory();
            } else {
              _nextStory();
            }
          },
          onTapCancel: () => _progressController.forward(),
          child: Stack(
            children: [
              // Vibrant backdrop gradient with subtle ambient animation
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      story.ringColor.withValues(alpha: 0.35),
                      AppColors.background,
                    ],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: story.ringColor.withValues(alpha: 0.2),
                            border: Border.all(color: story.ringColor, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: story.ringColor.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(story.icon, size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.85),
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
                              const SizedBox(height: 12),
                              Text(
                                '"${story.caption}"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
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
                            margin: const EdgeInsets.symmetric(horizontal: 2),
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
                    const SizedBox(height: 12),

                    // Author info & Close button
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: story.ringColor,
                          child: Text(
                            story.authorName.split(' ').map((s) => s[0]).take(2).join(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              story.authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${story.communityName} • ${story.timeAgo}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 24),
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
