import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:story_view/story_view.dart' as sv;
import 'package:story_view/story_view.dart' hide StoryItem;
import 'package:quest/features/interaction/home/data/stories_provider.dart' as sp;
import 'package:quest/core/utils/time_utils.dart';
import 'package:quest/shared/widgets/expandable_caption.dart';

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
  final StoryController controller = StoryController();
  late List<sp.StoryItem> _stories;
  late List<sv.StoryItem> _storyItems;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _stories = widget.customStories ?? ref.read(sp.storiesProvider).value ?? [];
    _currentIndex = widget.initialIndex;

    _storyItems = _stories.map((s) {
      if ((s.muxPlaybackId != null && s.muxPlaybackId!.isNotEmpty) ||
          (s.videoUrl != null && s.videoUrl!.isNotEmpty)) {
        final url = s.muxPlaybackId != null && s.muxPlaybackId!.isNotEmpty
            ? 'https://stream.mux.com/${s.muxPlaybackId!}.m3u8'
            : s.videoUrl!;
        return sv.StoryItem.pageVideo(
          url,
          controller: controller,
          key: ValueKey(s.id),
        );
      } else if (s.content != null && s.content!.isNotEmpty) {
        return sv.StoryItem.pageImage(
          url: s.content!,
          controller: controller,
          imageFit: BoxFit.contain,
          key: ValueKey(s.id),
        );
      } else {
        // Fallback for text-only stories (e.g. mock stories)
        return sv.StoryItem.text(
          title: s.caption.isNotEmpty ? s.caption : 'No content',
          backgroundColor: (s.gradient != null && s.gradient!.isNotEmpty) 
              ? s.gradient!.first 
              : s.ringColor,
        );
      }
    }).toList();

    // Slice lists starting from initialIndex to prevent the viewer from starting at 0
    if (_currentIndex > 0 && _currentIndex < _storyItems.length) {
       _storyItems = _storyItems.sublist(_currentIndex);
       _stories = _stories.sublist(_currentIndex);
       _currentIndex = 0;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onStoryShow(sv.StoryItem s, int pos) {
    final index = _storyItems.indexOf(s);
    if (index != -1 && mounted && _currentIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = index;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_stories.isEmpty || _storyItems.isEmpty) return const SizedBox.shrink();

    final currentAppStory = _stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          StoryView(
            storyItems: _storyItems,
            controller: controller,
            onStoryShow: _onStoryShow,
            onComplete: () {
              Navigator.pop(context);
            },
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
                    backgroundImage: currentAppStory.authorAvatar != null
                        ? NetworkImage(currentAppStory.authorAvatar!)
                        : null,
                    child: currentAppStory.authorAvatar == null
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
                          currentAppStory.authorName,
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
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
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
        ],
      ),
    );
  }
}
