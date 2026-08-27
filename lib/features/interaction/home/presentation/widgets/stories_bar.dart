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
      height: 116,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: stories.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "My Story" button
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/create'); 
              },
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.border, width: 2),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              color: context.colors.textMuted,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: context.colors.questBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.colors.background, width: 2),
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    'My Story',
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
                  width: 72,
                  height: 72,
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
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: story.authorAvatar != null && story.authorAvatar!.isNotEmpty
                        ? Image.network(
                            story.authorAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackIcon(story, context),
                          )
                        : _buildFallbackIcon(story, context),
                  ),
                ),
                SizedBox(height: 6),
                SizedBox(
                  width: 74,
                  child: Text(
                    story.authorName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasSeen ? context.colors.textMuted : Colors.white,
                      fontSize: 11,
                      fontWeight: hasSeen ? FontWeight.normal : FontWeight.w700,
                      height: 1.2,
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

  Widget _buildFallbackIcon(StoryItem story, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: story.ringColor.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          story.icon,
          color: story.ringColor,
          size: 32,
        ),
      ),
    );
  }
}
