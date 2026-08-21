import 'package:flutter/material.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
/// Quest's primary button with glow effect
class QuestButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final QuestButtonVariant variant;
  final bool isFullWidth;
  final IconData? icon;

  const QuestButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = QuestButtonVariant.primary,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  State<QuestButton> createState() => _QuestButtonState();
}

class _QuestButtonState extends State<QuestButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    List<BoxShadow> shadows;

    switch (widget.variant) {
      case QuestButtonVariant.secondary:
        bgColor = context.colors.card;
        fgColor = Colors.white;
        shadows = [];
        break;
      case QuestButtonVariant.xp:
        bgColor = context.colors.gold;
        fgColor = Colors.black;
        shadows = [
          BoxShadow(
            color: context.colors.gold.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ];
        break;
      case QuestButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = context.colors.textSecondary;
        shadows = [];
        break;
      case QuestButtonVariant.primary:
        bgColor = context.colors.questBlue;
        fgColor = Colors.white;
        shadows = [
          BoxShadow(
            color: context.colors.questBlue.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ];
        break;
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: widget.isFullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: widget.variant == QuestButtonVariant.secondary
                ? Border.all(color: context.colors.border)
                : null,
            boxShadow: shadows,
          ),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            mainAxisSize: widget.isFullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fgColor, size: 20),
                SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum QuestButtonVariant { primary, secondary, xp, ghost }
