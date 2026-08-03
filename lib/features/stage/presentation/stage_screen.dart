import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/quest_icons.dart';
import '../data/stage_provider.dart';

class StageScreen extends ConsumerStatefulWidget {
  final String stageId;

  const StageScreen({
    super.key,
    required this.stageId,
  });

  @override
  ConsumerState<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends ConsumerState<StageScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageState = ref.watch(stageProvider);
    final stageNotifier = ref.read(stageProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    AppColors.auroraPurple.withValues(alpha: 0.25),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
                        tooltip: 'Minimize',
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/events');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.crimson.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.crimson.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _pulseController,
                                        builder: (context, child) {
                                          return Container(
                                            width: 7,
                                            height: 7,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.crimson.withValues(
                                                alpha: 0.5 + (_pulseController.value * 0.5),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'LIVE STAGE',
                                        style: TextStyle(
                                          color: AppColors.crimson,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  stageState.communityName,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stageState.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, color: AppColors.questBlue, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${stageState.speakers.length + stageState.audience.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(color: AppColors.border, height: 1),

                // Main Stage Area
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    children: [
                      // Topic Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                stageState.topic,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Speakers Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SPEAKERS ON STAGE',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${stageState.speakers.length}',
                            style: const TextStyle(color: AppColors.questBlue, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: stageState.speakers.length,
                        itemBuilder: (context, index) {
                          final speaker = stageState.speakers[index];
                          return _buildSpeakerTile(speaker);
                        },
                      ),
                      const SizedBox(height: 32),

                      // Audience & Raised Hands
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'AUDIENCE & LISTENERS',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${stageState.audience.length}',
                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: stageState.audience.length,
                        itemBuilder: (context, index) {
                          final listener = stageState.audience[index];
                          return _buildAudienceTile(listener);
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // Bottom Stage Controls
                _buildBottomControls(stageState, stageNotifier),
              ],
            ),
          ),

          // Floating Reactions Overlay
          ...stageState.activeReactions.map((reaction) => _buildFloatingReaction(reaction)),
        ],
      ),
    );
  }

  Widget _buildSpeakerTile(StageSpeaker speaker) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Speaking Pulse Ring
            if (speaker.isSpeaking)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 78 + (_pulseController.value * 8),
                    height: 78 + (_pulseController.value * 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.8 - (_pulseController.value * 0.4)),
                        width: 2.5,
                      ),
                    ),
                  );
                },
              ),

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: speaker.isSpeaking ? AppColors.emerald : AppColors.border,
                  width: speaker.isSpeaking ? 2 : 1,
                ),
                image: DecorationImage(
                  image: NetworkImage(speaker.avatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Mute / Archetype Badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: speaker.isMuted ? AppColors.crimson : AppColors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Icon(
                  speaker.isMuted ? Icons.mic_off : QuestIcons.forArchetype(speaker.archetype),
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          speaker.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        Text(
          speaker.role,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildAudienceTile(StageParticipant listener) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(listener.avatar),
            ),
            if (listener.hasHandRaised)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pan_tool_rounded, color: Colors.black, size: 10),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          listener.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBottomControls(StageState state, StageNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji quick bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['🔥', '🚀', '💡', '👏', '❤️'].map((emoji) {
              return GestureDetector(
                onTap: () => notifier.sendReaction(emoji),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Control buttons
          Row(
            children: [
              // Mute toggle
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.isMicMuted ? Colors.white70 : AppColors.emerald,
                    backgroundColor: state.isMicMuted ? AppColors.card : AppColors.emerald.withValues(alpha: 0.15),
                    side: BorderSide(color: state.isMicMuted ? AppColors.border : AppColors.emerald),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(state.isMicMuted ? Icons.mic_off : Icons.mic, size: 20),
                  label: Text(state.isMicMuted ? 'Muted' : 'Speaking'),
                  onPressed: notifier.toggleMic,
                ),
              ),
              const SizedBox(width: 8),

              // Raise Hand toggle
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.isHandRaised ? Colors.black : Colors.white,
                    backgroundColor: state.isHandRaised ? AppColors.gold : AppColors.card,
                    side: BorderSide(color: state.isHandRaised ? AppColors.gold : AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.pan_tool_rounded, size: 18, color: state.isHandRaised ? Colors.black : AppColors.gold),
                  label: Text(
                    state.isHandRaised ? 'Hand Raised' : 'Raise Hand',
                    style: TextStyle(color: state.isHandRaised ? Colors.black : Colors.white),
                  ),
                  onPressed: notifier.toggleHandRaise,
                ),
              ),
              const SizedBox(width: 8),

              // Leave button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.crimson.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.crimson),
                  ),
                ),
                icon: const Icon(Icons.call_end, color: AppColors.crimson),
                tooltip: 'Leave stage',
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/events');
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingReaction(StageReaction reaction) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(reaction.id),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1800),
      builder: (context, value, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final bottomOffset = 120.0 + (value * (screenHeight * 0.5));
        final leftOffset = (screenWidth * reaction.xOffset) + (15 * (value % 2 == 0 ? 1 : -1));
        final opacity = (1.0 - value).clamp(0.0, 1.0);

        return Positioned(
          bottom: bottomOffset,
          left: leftOffset,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: 0.8 + (value * 0.6),
              child: Text(
                reaction.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
}
