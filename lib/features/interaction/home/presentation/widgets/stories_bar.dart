import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/interaction/home/data/stories_provider.dart';
import 'story_viewer_modal.dart';
import 'my_status_modal.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class StoriesBar extends ConsumerWidget {
  const StoriesBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storiesAsync = ref.watch(storiesProvider);
    final allStories = storiesAsync.value ?? [];

    final myStories = allStories
        .where((s) => s.isMe)
        .toList();
    final otherStories = allStories
        .where((s) => !myStories.contains(s))
        .toList();
    final hasMyStories = myStories.isNotEmpty;

    return SizedBox(
      height: 116,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: otherStories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "My Story" button with WhatsApp-style status flow
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (hasMyStories) {
                  MyStatusModal.show(context, myStories: myStories);
                } else {
                  context.push('/create');
                }
              },
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: hasMyStories
                                ? context.colors.questBlue
                                : context.colors.border,
                            width: hasMyStories ? 2.5 : 2.0,
                          ),
                          boxShadow: hasMyStories
                              ? [
                                  BoxShadow(
                                    color: context.colors.questBlue.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Center(
                            child: hasMyStories
                                ? _buildMyStoryAvatar(myStories.first, context)
                                : Icon(
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
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: context.colors.questBlue,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.colors.background,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            hasMyStories ? Icons.camera_alt : Icons.add,
                            color: Colors.white,
                            size: hasMyStories ? 13 : 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'My Story',
                    style: TextStyle(
                      color: hasMyStories
                          ? context.colors.questBlue
                          : context.colors.textSecondary,
                      fontSize: 11,
                      fontWeight: hasMyStories
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          final story = otherStories[index - 1];
          final hasSeen = story.isSeen;

          return GestureDetector(
            onTap: () => StoryViewerModal.show(
              context,
              customStories: otherStories,
              initialIndex: index - 1,
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(2.5),
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
                    child:
                        story.authorAvatar != null &&
                            story.authorAvatar!.isNotEmpty
                        ? Image.network(
                            story.authorAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFallbackIcon(story, context),
                          )
                        : _buildFallbackIcon(story, context),
                  ),
                ),
                const SizedBox(height: 6),
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
      child: Center(child: Icon(story.icon, color: story.ringColor, size: 32)),
    );
  }

  Widget _buildMyStoryAvatar(StoryItem story, BuildContext context) {
    if (story.muxPlaybackId != null && story.muxPlaybackId!.isNotEmpty) {
      return Image.network(
        'https://image.mux.com/${story.muxPlaybackId}/thumbnail.jpg',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildFallbackIcon(story, context),
      );
    } else if (story.content != null && story.content!.startsWith('http')) {
      return Image.network(
        story.content!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildFallbackIcon(story, context),
      );
    } else if (story.authorAvatar != null && story.authorAvatar!.isNotEmpty) {
      return Image.network(
        story.authorAvatar!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildFallbackIcon(story, context),
      );
    }
    return _buildFallbackIcon(story, context);
  }
}
