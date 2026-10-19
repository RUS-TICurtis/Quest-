import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/interaction/stage/data/stage_provider.dart';
import 'package:quest/features/interaction/stage/data/stage_repository.dart';

/// Modal bottom sheet allowing verified members to launch a new live audio Stage.
class StartStageSheet extends ConsumerStatefulWidget {
  final String? defaultCommunity;

  const StartStageSheet({super.key, this.defaultCommunity});

  static Future<void> show(BuildContext context, {String? defaultCommunity}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StartStageSheet(defaultCommunity: defaultCommunity),
    );
  }

  @override
  ConsumerState<StartStageSheet> createState() => _StartStageSheetState();
}

class _StartStageSheetState extends ConsumerState<StartStageSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _topicController;
  late final TextEditingController _communityController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _topicController = TextEditingController();
    _communityController =
        TextEditingController(text: widget.defaultCommunity ?? 'Christian Technologists');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  Future<void> _handleLaunchStage() async {
    final auth = ref.read(authProvider);
    if (auth.accessLevel != AccessLevel.member || auth.user == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Members only: Please sign in or create an account to host a Stage.',
          ),
          backgroundColor: AppColors.crimson,
          action: SnackBarAction(
            label: 'Sign In',
            textColor: Colors.white,
            onPressed: () => context.push('/login'),
          ),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    try {
      final user = auth.user!;
      final profile = ref.read(userProvider).value;

      final host = StageSpeaker(
        id: user.id,
        name: profile?.name ?? 'Host',
        role: 'Host • Creator',
        avatar: (profile?.avatarUrl != null && profile!.avatarUrl!.isNotEmpty)
            ? profile.avatarUrl!
            : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        isMuted: false,
        isSpeaking: true,
        archetype: profile?.archetypes.firstOrNull ?? 'Visionary',
      );

      final newStage = await ref.read(stageRepositoryProvider).createStage(
            title: _titleController.text.trim(),
            topic: _topicController.text.trim(),
            communityName: _communityController.text.trim(),
            host: host,
          );

      ref.invalidate(activeStagesProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      context.push('/stage/${newStage.stageId}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start stage: $e'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.crimson.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.mic_rounded,
                        color: context.colors.crimson,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Host a Live Stage',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Broadcast live audio fellowship to your community',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'STAGE TITLE',
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., Evening Devotional & Tech Reflection',
                    hintStyle: TextStyle(
                      color: context.colors.textMuted.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: context.colors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.questBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a stage title'
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  'TOPIC / PROMPT',
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _topicController,
                  maxLines: 2,
                  style: TextStyle(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., Discussing ethics, faith, and velocity in engineering teams',
                    hintStyle: TextStyle(
                      color: context.colors.textMuted.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: context.colors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.questBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a topic or discussion prompt'
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  'COMMUNITY TAG',
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _communityController,
                  style: TextStyle(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g., Christian Technologists',
                    hintStyle: TextStyle(
                      color: context.colors.textMuted.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: context.colors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.colors.questBlue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Please enter a community tag'
                      : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.crimson,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _handleLaunchStage,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Go Live Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
