import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/quest_icons.dart';
import 'package:quest/features/interaction/stage/data/stage_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class StageScreen extends ConsumerStatefulWidget {
  final String stageId;

  const StageScreen({super.key, required this.stageId});

  @override
  ConsumerState<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends ConsumerState<StageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stageStateAsync = ref.watch(stageProvider(widget.stageId));
    final stageState = stageStateAsync.value;
    final stageNotifier = ref.read(stageProvider(widget.stageId).notifier);

    if (stageState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.questBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: Stack(
        children: [
          // Background Gradient Mesh
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.6),
                  radius: 1.2,
                  colors: [
                    context.colors.auroraPurple.withValues(alpha: 0.25),
                    context.colors.background,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: context.colors.textPrimary,
                          size: 28,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/events');
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.crimson.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: context.colors.crimson.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
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
                                              color: context.colors.crimson
                                                  .withValues(
                                                    alpha:
                                                        0.5 +
                                                        (_pulseController
                                                                .value *
                                                            0.5),
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'LIVE STAGE',
                                        style: TextStyle(
                                          color: context.colors.crimson,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  stageState.communityName,
                                  style: TextStyle(
                                    color: context.colors.textMuted,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Text(
                              stageState.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              color: context.colors.questBlue,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${stageState.speakers.length + stageState.audience.length}',
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(color: context.colors.border, height: 1),

                // Main Stage Area
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    children: [
                      // Topic Card
                      Container(
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.colors.card.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: context.colors.gold,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                stageState.topic,
                                style: TextStyle(
                                  color: context.colors.textPrimary70,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),

                      // Speakers Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SPEAKERS ON STAGE',
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${stageState.speakers.length}',
                            style: TextStyle(
                              color: context.colors.questBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
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
                      SizedBox(height: 32),

                      // Audience & Raised Hands
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'AUDIENCE & LISTENERS',
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${stageState.audience.length}',
                            style: TextStyle(
                              color: context.colors.textPrimary54,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
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
                      SizedBox(height: 80),
                    ],
                  ),
                ),

                // Bottom Stage Controls
                _buildBottomControls(stageState, stageNotifier),
              ],
            ),
          ),

          // Floating Reactions Overlay
          ...stageState.activeReactions.map(
            (reaction) => _buildFloatingReaction(reaction),
          ),
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
                    width: 78 + (_pulseController.value * 10),
                    height: 78 + (_pulseController.value * 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.emerald.withValues(
                          alpha: 0.8 - (_pulseController.value * 0.45),
                        ),
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
                  color: speaker.isSpeaking
                      ? context.colors.emerald
                      : context.colors.border,
                  width: speaker.isSpeaking ? 2.5 : 1,
                ),
                image: DecorationImage(
                  image: NetworkImage(speaker.avatar),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Live Audio Equalizer Wave Badge (when speaking)
            if (speaker.isSpeaking)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.emerald,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.emerald.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (barIndex) {
                              final barHeight =
                                  4.0 +
                                  (sin(
                                        (_pulseController.value * 2 * pi) +
                                            (barIndex * 1.5),
                                      ).abs() *
                                      8.0);
                              return Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 0.8,
                                ),
                                width: 2,
                                height: barHeight,
                                decoration: BoxDecoration(
                                  color: context.colors.background,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // Mute / Archetype Badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: speaker.isMuted ? context.colors.crimson : context.colors.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 1.5),
                ),
                child: Icon(
                  speaker.isMuted
                      ? Icons.mic_off
                      : QuestIcons.forArchetype(speaker.archetype),
                  color: context.colors.textPrimary,
                  size: 13,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          speaker.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          speaker.role,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.colors.textMuted, fontSize: 10),
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
                  padding: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.colors.gold,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pan_tool_rounded,
                    color: context.colors.background,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 6),
        Text(
          listener.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.colors.textPrimary70, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBottomControls(StageState state, StageNotifier notifier) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.border)),
        boxShadow: [
          BoxShadow(
            color: context.colors.background.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: Offset(0, -4),
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  HapticFeedback.lightImpact();
                  notifier.sendReaction(emoji);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Text(emoji, style: TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 12),

          // Control buttons
          Row(
            children: [
              // Mute toggle
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.isMicMuted
                        ? context.colors.textPrimary70
                        : context.colors.emerald,
                    backgroundColor: state.isMicMuted
                        ? context.colors.card
                        : context.colors.emerald.withValues(alpha: 0.15),
                    side: BorderSide(
                      color: state.isMicMuted
                          ? context.colors.border
                          : context.colors.emerald,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    state.isMicMuted ? Icons.mic_off : Icons.mic,
                    size: 20,
                  ),
                  label: Text(state.isMicMuted ? 'Muted' : 'Speaking'),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    HapticFeedback.mediumImpact();
                    notifier.toggleMic();
                  },
                ),
              ),
              SizedBox(width: 8),

              // Raise Hand toggle
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: state.isHandRaised
                        ? context.colors.background
                        : context.colors.textPrimary,
                    backgroundColor: state.isHandRaised
                        ? context.colors.gold
                        : context.colors.card,
                    side: BorderSide(
                      color: state.isHandRaised
                          ? context.colors.gold
                          : context.colors.border,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(
                    Icons.pan_tool_rounded,
                    size: 18,
                    color: state.isHandRaised
                        ? context.colors.background
                        : context.colors.gold,
                  ),
                  label: Text(
                    state.isHandRaised ? 'Hand Raised' : 'Raise Hand',
                    style: TextStyle(
                      color: state.isHandRaised
                          ? context.colors.background
                          : context.colors.textPrimary,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    HapticFeedback.selectionClick();
                    notifier.toggleHandRaise();
                  },
                ),
              ),
              SizedBox(width: 8),

              // Leave button
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: context.colors.crimson.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.colors.crimson),
                  ),
                ),
                icon: Icon(Icons.call_end, color: context.colors.crimson),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  HapticFeedback.lightImpact();
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
      duration: Duration(milliseconds: 1800),
      builder: (context, value, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;
        final bottomOffset = 120.0 + (value * (screenHeight * 0.52));
        final horizontalSway = sin(value * pi * 3) * 24.0;
        final leftOffset = (screenWidth * reaction.xOffset) + horizontalSway;
        final opacity = (1.0 - value).clamp(0.0, 1.0);

        return Positioned(
          bottom: bottomOffset,
          left: leftOffset,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: sin(value * pi * 2) * 0.25,
              child: Transform.scale(
                scale: 0.85 + (value * 0.5),
                child: Text(
                  reaction.emoji,
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
