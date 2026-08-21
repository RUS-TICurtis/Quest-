import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quest/shared/widgets/quest_button.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final VoidCallback onDismiss;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required int newLevel,
    required VoidCallback onDismiss,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      HapticFeedback.heavyImpact();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            LevelUpDialog(newLevel: newLevel, onDismiss: onDismiss),
      );
    });
  }

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.colors.gold.withValues(alpha: 0.6),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: context.colors.gold.withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Glowing Trophy Crest
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          context.colors.gold,
                          Colors.amber.shade700,
                          context.colors.auroraPurple,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: context.colors.gold.withValues(
                            alpha: _glowAnimation.value,
                          ),
                          blurRadius: 30,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.newLevel}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),

              Text(
                'LEVEL UP!',
                style: TextStyle(
                  color: context.colors.gold,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),

              Text(
                'You reached Level ${widget.newLevel} and unlocked higher reputation standing!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),

              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.workspace_premium,
                      color: context.colors.gold,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '+500 Bonus Guild Credibility',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 28),

              QuestButton(
                label: 'Claim & Continue',
                variant: QuestButtonVariant.xp,
                isFullWidth: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onDismiss();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
