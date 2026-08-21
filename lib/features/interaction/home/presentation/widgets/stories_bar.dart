import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/interaction/home/data/stories_provider.dart';
import 'story_viewer_modal.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final stories = storiesAsync.value ?? [];

    return SizedBox(
      height: 104,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "Your Story" / "Share Update" button
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/create-story');
              },
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.surface,
                          border: Border.all(color: context.colors.border, width: 2),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.add,
                            color: context.colors.questBlue,
                            size: 28,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: context.colors.questBlue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Share Live',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final story = stories[index - 1];
          final hasSeen = story.isSeen;

          return GestureDetector(
            onTap: () =>
                StoryViewerModal.show(context, initialIndex: index - 1),
            child: Column(
              children: [
                Container(
                  width: 66,
                  height: 66,
                  padding: EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasSeen
                        ? null
                        : LinearGradient(
                            colors: [
                              story.ringColor,
                              context.colors.auroraPurple,
                              context.colors.questBlue,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    border: hasSeen
                        ? Border.all(color: context.colors.border, width: 2)
                        : null,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: story.ringColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          story.icon,
                          color: story.ringColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 6),
                SizedBox(
                  width: 70,
                  child: Text(
                    story.authorName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasSeen ? context.colors.textMuted : Colors.white,
                      fontSize: 11,
                      fontWeight: hasSeen ? FontWeight.normal : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
