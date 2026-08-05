import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class VoiceNoteBubble extends StatefulWidget {
  final int durationSeconds;
  final bool isMe;

  const VoiceNoteBubble({
    super.key,
    required this.durationSeconds,
    required this.isMe,
  });

  @override
  State<VoiceNoteBubble> createState() => _VoiceNoteBubbleState();
}

class _VoiceNoteBubbleState extends State<VoiceNoteBubble>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _animController;
  int _currentSecond = 0;

  final List<double> _waveformHeights = [
    0.3, 0.6, 0.9, 0.5, 0.8, 1.0, 0.4, 0.7, 0.9, 0.6, 0.3, 0.8, 0.5, 0.9, 0.7, 0.4, 0.6, 0.3
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds > 0 ? widget.durationSeconds : 10),
    )..addListener(() {
        setState(() {
          _currentSecond = (_animController.value * widget.durationSeconds).toInt();
        });
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _isPlaying = false;
          });
          _animController.reset();
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.forward();
      } else {
        _animController.stop();
      }
    });
  }

  void _seekTo(double ratio) {
    HapticFeedback.lightImpact();
    final targetValue = ratio.clamp(0.0, 1.0);
    _animController.value = targetValue;
    setState(() {
      _currentSecond = (targetValue * widget.durationSeconds).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isMe ? Colors.white : AppColors.questBlue;
    final inactiveColor = widget.isMe ? Colors.white38 : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isMe ? Colors.white.withValues(alpha: 0.2) : AppColors.questBlue.withValues(alpha: 0.15),
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: activeColor,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform bars with seek gesture
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                final box = context.findRenderObject() as RenderBox?;
                if (box != null) {
                  final localX = details.localPosition.dx;
                  final width = box.size.width - 90;
                  if (width > 0) {
                    _seekTo((localX / width).clamp(0.0, 1.0));
                  }
                }
              },
              child: SizedBox(
                height: 28,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_waveformHeights.length, (index) {
                    final progress = _animController.value;
                    final barProgress = index / _waveformHeights.length;
                    final isPlayed = barProgress <= progress;

                    return Container(
                      width: 3,
                      height: 28 * _waveformHeights[index],
                      decoration: BoxDecoration(
                        color: isPlayed ? activeColor : inactiveColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Duration Text
          Text(
            _isPlaying
                ? '0:${_currentSecond.toString().padLeft(2, '0')}'
                : '0:${widget.durationSeconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: widget.isMe ? Colors.white70 : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
