import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_view/story_view.dart' as sv;
import 'package:story_view/story_view.dart' hide StoryItem;
import 'package:quest/features/interaction/home/data/stories_provider.dart' as sp;
import 'package:quest/core/utils/time_utils.dart';
import 'package:quest/shared/widgets/expandable_caption.dart';

class _UserStoryGroup {
  final String authorName;
  final String? authorAvatar;
  final List<sp.StoryItem> stories;

  _UserStoryGroup({
    required this.authorName,
    this.authorAvatar,
    required this.stories,
  });
}

class StoryViewerModalV2 extends ConsumerStatefulWidget {
  final int initialIndex;
  final List<sp.StoryItem>? customStories;

  const StoryViewerModalV2({
    super.key,
    this.initialIndex = 0,
    this.customStories,
  });

  static void show(
    BuildContext context, {
    int initialIndex = 0,
    List<sp.StoryItem>? customStories,
  }) {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Story Viewer',
      barrierColor: Colors.black.withValues(alpha: 0.92),
      pageBuilder: (context, anim1, anim2) {
        return StoryViewerModalV2(
          initialIndex: initialIndex,
          customStories: customStories,
        );
      },
    );
  }

  @override
  ConsumerState<StoryViewerModalV2> createState() => _StoryViewerModalV2State();
}

class _StoryViewerModalV2State extends ConsumerState<StoryViewerModalV2> {
  late PageController _pageController;
  late List<_UserStoryGroup> _userGroups;
  late List<StoryController> _storyControllers;
  int _currentUserIndex = 0;
  int _currentStoryIndex = 0;

  @override
  void initState() {
    super.initState();
    final allStories = widget.customStories ?? ref.read(sp.storiesProvider).value ?? [];

    // Group stories by author
    final Map<String, _UserStoryGroup> grouped = {};
    for (var story in allStories) {
      if (!grouped.containsKey(story.authorName)) {
        grouped[story.authorName] = _UserStoryGroup(
          authorName: story.authorName,
          authorAvatar: story.authorAvatar,
          stories: [],
        );
      }
      grouped[story.authorName]!.stories.add(story);
    }

    _userGroups = grouped.values.toList();
    _storyControllers = List.generate(_userGroups.length, (_) => StoryController());

    // Find which user group contains the initial story
    if (widget.initialIndex > 0 && widget.initialIndex < allStories.length) {
      final targetStory = allStories[widget.initialIndex];
      _currentUserIndex = _userGroups.indexWhere((g) => g.authorName == targetStory.authorName);
      if (_currentUserIndex == -1) _currentUserIndex = 0;
      
      _currentStoryIndex = _userGroups[_currentUserIndex].stories.indexWhere((s) => s.id == targetStory.id);
      if (_currentStoryIndex == -1) _currentStoryIndex = 0;
    }

    _pageController = PageController(initialPage: _currentUserIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _storyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onStoryComplete() {
    if (_currentUserIndex < _userGroups.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  List<sv.StoryItem> _buildStoryItems(_UserStoryGroup group, int groupIndex) {
    return group.stories.map((s) {
      if ((s.muxPlaybackId != null && s.muxPlaybackId!.isNotEmpty) ||
          (s.videoUrl != null && s.videoUrl!.isNotEmpty)) {
        final url = s.muxPlaybackId != null && s.muxPlaybackId!.isNotEmpty
            ? 'https://stream.mux.com/${s.muxPlaybackId!}.m3u8'
            : s.videoUrl!;
        return sv.StoryItem.pageVideo(
          url,
          controller: _storyControllers[groupIndex],
          key: ValueKey(s.id),
        );
      } else if (s.content != null && s.content!.isNotEmpty) {
        return sv.StoryItem.pageImage(
          url: s.content!,
          controller: _storyControllers[groupIndex],
          imageFit: BoxFit.contain,
          key: ValueKey(s.id),
        );
      } else {
        return sv.StoryItem.text(
          title: s.caption.isNotEmpty ? s.caption : 'No content',
          backgroundColor: (s.gradient != null && s.gradient!.isNotEmpty) 
              ? s.gradient!.first 
              : s.ringColor,
        );
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_userGroups.isEmpty) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentUserIndex = index;
            _currentStoryIndex = 0;
          });
          // Pause all other controllers
          for (int i = 0; i < _storyControllers.length; i++) {
            if (i != index) {
              _storyControllers[i].pause();
            } else {
              _storyControllers[i].play();
            }
          }
        },
        itemCount: _userGroups.length,
        itemBuilder: (context, index) {
          final group = _userGroups[index];
          final storyItems = _buildStoryItems(group, index);
          
          // If we are navigating to this page, and we need to start at a specific story offset
          if (index == _currentUserIndex && _currentStoryIndex > 0) {
             // story_view does not have an initialIndex, we have to slice the list.
             // But we want progress bars for all of them. Since StoryView doesn't support starting
             // at an arbitrary index easily while keeping the full progress bar, we might just play from start
             // or slice it. We'll play from start for simplicity, or slice if strictly needed.
             // We'll leave it as is to keep the full progress bar, but they will restart if sliced.
          }

          final currentAppStory = group.stories[_currentStoryIndex < group.stories.length ? _currentStoryIndex : 0];

          return Stack(
            children: [
              StoryView(
                storyItems: storyItems,
                controller: _storyControllers[index],
                onStoryShow: (s, pos) {
                  final idx = storyItems.indexOf(s);
                  if (idx != -1 && mounted) {
                    setState(() {
                      _currentStoryIndex = idx;
                    });
                  }
                },
                onComplete: _onStoryComplete,
                onVerticalSwipeComplete: (direction) {
                  if (direction == Direction.down) {
                    Navigator.pop(context);
                  }
                },
              ),
              
              // Top Overlay
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0, left: 16, right: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: group.authorAvatar != null
                            ? NetworkImage(group.authorAvatar!)
                            : null,
                        child: group.authorAvatar == null
                            ? const Icon(Icons.person, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              group.authorName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                            ),
                            if (currentAppStory.createdAt != null)
                              Text(
                                TimeUtils.formatStoryTime(currentAppStory.createdAt!),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Caption Overlay
              if (currentAppStory.caption.isNotEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 84,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExpandableCaption(
                      text: currentAppStory.caption,
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                      ),
                    ),
                  ),
                ),

              // Bottom Interaction Bar (Views count for owner, Reactions & Reply for others)
              if (currentAppStory.isMe)
                Positioned(
                  bottom: 24,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${currentAppStory.viewsCount} ${currentAppStory.viewsCount == 1 ? "view" : "views"}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Direct message reply to @${group.authorName} coming soon!',
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Reply to ${group.authorName}…',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...['🔥', '❤️', '👏', '🎯'].map((emoji) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Sent $emoji to @${group.authorName}!',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
