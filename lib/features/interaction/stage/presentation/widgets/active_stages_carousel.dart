import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/stage/data/stage_provider.dart';
import 'package:quest/features/interaction/stage/data/stage_repository.dart';
import 'start_stage_sheet.dart';

/// Interactive discovery carousel for active live audio Stages & Firesides.
class ActiveStagesCarousel extends ConsumerWidget {
  final String? communityFilter;

  const ActiveStagesCarousel({super.key, this.communityFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(activeStagesProvider);

    return stagesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stages) {
        final filteredStages = communityFilter != null
            ? stages
                .where((s) =>
                    s.communityName.toLowerCase() ==
                    communityFilter!.toLowerCase())
                .toList()
            : stages;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colors.crimson,
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.crimson.withValues(alpha: 0.6),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Stages',
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(Icons.add, size: 16, color: context.colors.crimson),
                    label: Text(
                      'Host Stage',
                      style: TextStyle(
                        color: context.colors.crimson,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      StartStageSheet.show(
                        context,
                        defaultCommunity: communityFilter,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (filteredStages.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mic_none_rounded, color: context.colors.textMuted, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No live rooms right now. Host a live stage for fellowship!',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          StartStageSheet.show(
                            context,
                            defaultCommunity: communityFilter,
                          );
                        },
                        child: Text(
                          'Go Live',
                          style: TextStyle(
                            color: context.colors.questBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 145,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredStages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final stage = filteredStages[index];
                    return _buildStageCard(context, stage);
                  },
                ),
              ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }

  Widget _buildStageCard(BuildContext context, StageState stage) {
    final totalParticipants = stage.speakers.length + stage.audience.length;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.crimson.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: context.colors.crimson.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.crimson,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: context.colors.crimson,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stage.communityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.questBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headset_rounded, size: 12, color: context.colors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '$totalParticipants',
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stage.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stage.topic,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 11.5,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              // Avatar Stack
              SizedBox(
                height: 24,
                width: 44,
                child: Stack(
                  children: [
                    for (int i = 0; i < stage.speakers.take(2).length; i++)
                      Positioned(
                        left: i * 16.0,
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: context.colors.surface,
                          child: CircleAvatar(
                            radius: 11,
                            backgroundImage: NetworkImage(stage.speakers[i].avatar),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  stage.speakers.firstOrNull?.name ?? 'Host',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                height: 28,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.questBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/stage/${stage.stageId}');
                  },
                  child: const Text(
                    'Tune In',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
