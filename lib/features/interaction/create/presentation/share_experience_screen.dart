import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:quest/core/theme/app_colors.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/core/media/media_service_gateway.dart';
import 'package:quest/core/media/media_purpose.dart';
import 'package:quest/core/services/app_notification_service.dart';
import 'package:quest/features/interaction/create/data/models/create_submission_payload.dart';
import 'package:quest/features/interaction/home/data/stories_provider.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:quest/features/interaction/feed/data/feed_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';

class ShareExperienceScreen extends ConsumerStatefulWidget {
  final CreateSubmissionPayload? payload;
  final String? mediaPath;

  const ShareExperienceScreen({
    super.key,
    this.payload,
    this.mediaPath,
  });

  @override
  ConsumerState<ShareExperienceScreen> createState() =>
      _ShareExperienceScreenState();
}

class _ShareExperienceScreenState extends ConsumerState<ShareExperienceScreen> {
  // Destinations
  bool _shareToStory = true;
  bool _shareToFeed = true;
  bool _shareToCommunities = false;
  Community? _selectedCommunity;

  // Quest Linking
  QuestItem? _selectedQuest;

  final List<String> _taggedUsers = [];
  bool _isUploading = false;
  String _uploadStatus = 'Preparing…';
  bool _usedFallback = false;
  final TextEditingController _captionController = TextEditingController();

  // Media state
  VideoPlayerController? _videoPlayerController;
  bool _isMuted = false;
  bool _isVideoPaused = false;
  bool _isTextMode = false;
  bool _isVideoMode = false;
  String? _effectiveMediaPath;
  Color _textCardColor = AppColors.questBlue;

  bool _isVideo(String path) {
    if (_isVideoMode) return true;
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.mkv') ||
        lowerPath.endsWith('.webm') ||
        (lowerPath.startsWith('blob:') && _isVideoMode);
  }

  bool get _isCurrentVideo =>
      _isVideoMode || (_effectiveMediaPath != null && _isVideo(_effectiveMediaPath!));

  @override
  void initState() {
    super.initState();

    if (widget.payload != null) {
      if (widget.payload!.isText) {
        _isTextMode = true;
        _textCardColor = widget.payload!.textBackgroundColor ?? AppColors.questBlue;
        _captionController.text = widget.payload!.textContent ?? '';
      } else {
        _effectiveMediaPath = widget.payload!.mediaPath;
        _isVideoMode = widget.payload!.isVideo;
      }
    } else if (widget.mediaPath != null) {
      _effectiveMediaPath = widget.mediaPath;
      _isVideoMode = _isVideo(widget.mediaPath!);
    }

    if (_effectiveMediaPath != null && _isCurrentVideo) {
      _isVideoMode = true;
      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(_effectiveMediaPath!),
        );
      } else {
        _videoPlayerController = VideoPlayerController.file(
          File(_effectiveMediaPath!),
        );
      }
      _videoPlayerController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _videoPlayerController?.setLooping(true);
        _videoPlayerController?.play();
      }).catchError((e) {
        debugPrint('VideoPlayerController init error: $e');
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _toggleVideoPlayback() {
    if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (_videoPlayerController!.value.isPlaying) {
        _videoPlayerController!.pause();
        _isVideoPaused = true;
      } else {
        _videoPlayerController!.play();
        _isVideoPaused = false;
      }
    });
  }

  void _toggleAudioMute() {
    if (_videoPlayerController == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _isMuted = !_isMuted;
      _videoPlayerController!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _retakeMedia() {
    HapticFeedback.lightImpact();
    _videoPlayerController?.pause();
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    context.pop();
  }

  void _showQuestPicker() {
    HapticFeedback.lightImpact();
    final userState = ref.read(userProvider).value;
    final quests = userState?.dailyQuests ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Link to Active Quest',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_selectedQuest != null)
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedQuest = null);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(color: context.colors.crimson),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Verify real-world participation and earn bonus XP on publish.',
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                if (quests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No active quests right now.',
                        style: TextStyle(color: context.colors.textMuted),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: quests.length,
                      separatorBuilder: (_, _) => Divider(
                        color: context.colors.border.withValues(alpha: 0.5),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final quest = quests[index];
                        final isSelected = _selectedQuest?.id == quest.id;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.military_tech_outlined,
                              color: AppColors.gold,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            quest.title,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${quest.category} • +${quest.xp} XP',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: context.colors.questBlue,
                                )
                              : null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedQuest = quest);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCommunityPicker() {
    HapticFeedback.lightImpact();
    final communitiesAsync = ref.read(communitiesProvider);
    final communities = communitiesAsync.value?.communities ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = communities.where((c) {
              final q = query.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  c.description.toLowerCase().contains(q) ||
                  c.category.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Select Community',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_selectedCommunity != null)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCommunity = null;
                                _shareToCommunities = false;
                              });
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Clear',
                              style: TextStyle(color: context.colors.crimson),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      style: TextStyle(color: context.colors.textPrimary),
                      onChanged: (val) => setSheetState(() => query = val),
                      decoration: InputDecoration(
                        hintText: 'Search communities…',
                        hintStyle: TextStyle(color: context.colors.textMuted),
                        prefixIcon: Icon(
                          Icons.search,
                          color: context.colors.textMuted,
                        ),
                        filled: true,
                        fillColor: context.colors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                communities.isEmpty
                                    ? 'No communities available yet.'
                                    : 'No communities match "$query".',
                                style: TextStyle(
                                  color: context.colors.textMuted,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final comm = filtered[index];
                              final isSelected =
                                  _selectedCommunity?.id == comm.id;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: comm.accentColor
                                      .withValues(alpha: 0.15),
                                  child: Icon(comm.icon,
                                      color: comm.accentColor, size: 20),
                                ),
                                title: Text(
                                  comm.name,
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  '${comm.category} • ${comm.memberCount} members',
                                  style: TextStyle(
                                    color: context.colors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: context.colors.questBlue)
                                    : null,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _selectedCommunity = comm;
                                    _shareToCommunities = true;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTagPeoplePicker() {
    HapticFeedback.lightImpact();
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tag People',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_taggedUsers.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _taggedUsers.map((tag) {
                        return Chip(
                          label: Text('@$tag'),
                          backgroundColor: context.colors.questBlue
                              .withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: context.colors.questBlue,
                            fontWeight: FontWeight.bold,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setSheetState(() {
                              _taggedUsers.remove(tag);
                            });
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: textController,
                          style: TextStyle(color: context.colors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Enter username (e.g. jules)',
                            hintStyle:
                                TextStyle(color: context.colors.textMuted),
                            prefixText: '@',
                            prefixStyle:
                                TextStyle(color: context.colors.questBlue),
                            filled: true,
                            fillColor: context.colors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (val) {
                            final trimmed =
                                val.trim().replaceAll('@', '').toLowerCase();
                            if (trimmed.isNotEmpty &&
                                !_taggedUsers.contains(trimmed)) {
                              setSheetState(() {
                                _taggedUsers.add(trimmed);
                                textController.clear();
                              });
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: context.colors.questBlue,
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final trimmed = textController.text
                              .trim()
                              .replaceAll('@', '')
                              .toLowerCase();
                          if (trimmed.isNotEmpty &&
                              !_taggedUsers.contains(trimmed)) {
                            setSheetState(() {
                              _taggedUsers.add(trimmed);
                              textController.clear();
                            });
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.questBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMediaPreview() {
    if (_isTextMode) {
      // Elegant text status card preview
      return Container(
        height: 240,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              _textCardColor,
              _textCardColor.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _textCardColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'TEXT EXPERIENCE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  tooltip: 'Retake / edit text',
                  onPressed: _retakeMedia,
                ),
              ],
            ),
            const Spacer(),
            Text(
              _captionController.text.isNotEmpty
                  ? _captionController.text
                  : 'Your written insight will appear here…',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.35,
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    if (_effectiveMediaPath != null && _isCurrentVideo) {
      // Video Preview with Playback & Audio Controls
      final isInitialized = _videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized;

      return Container(
        constraints: const BoxConstraints(maxHeight: 340),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isInitialized)
              GestureDetector(
                onTap: _toggleVideoPlayback,
                child: AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Play / Pause central indicator
            if (isInitialized && _isVideoPaused)
              GestureDetector(
                onTap: _toggleVideoPlayback,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),

            // Top Retake action button
            Positioned(
              top: 12,
              left: 12,
              child: GestureDetector(
                onTap: _retakeMedia,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.replay, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Retake',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Audio Mute toggle
            if (isInitialized)
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _toggleAudioMute,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Photo Preview
    return Container(
      constraints: const BoxConstraints(maxHeight: 340),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_effectiveMediaPath != null)
            kIsWeb
                ? Image.network(
                    _effectiveMediaPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined,
                                size: 48, color: context.colors.textMuted),
                            const SizedBox(height: 8),
                            Text('Photo Preview',
                                style: TextStyle(color: context.colors.textMuted)),
                          ],
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(_effectiveMediaPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported_outlined,
                                size: 48, color: context.colors.textMuted),
                            const SizedBox(height: 8),
                            Text('Photo Preview',
                                style: TextStyle(color: context.colors.textMuted)),
                          ],
                        ),
                      );
                    },
                  )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 48, color: context.colors.textMuted),
                  const SizedBox(height: 8),
                  Text('Media Preview',
                      style: TextStyle(color: context.colors.textMuted)),
                ],
              ),
            ),

          // Retake button on photo
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: _retakeMedia,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.replay, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Retake',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationPill({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.questBlue.withValues(alpha: 0.15)
                : context.colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? context.colors.questBlue
                  : context.colors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected
                        ? context.colors.questBlue
                        : context.colors.textMuted,
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: context.colors.questBlue,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.colors.textMuted,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
        title: Text(
          'Share Experience',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Responsive Media Review Viewport
            _buildMediaPreview(),
            const SizedBox(height: 20),

            // 2. Active Quest Proof Banner
            GestureDetector(
              onTap: _showQuestPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedQuest != null
                      ? AppColors.gold.withValues(alpha: 0.12)
                      : context.colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedQuest != null
                        ? AppColors.gold
                        : context.colors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.military_tech,
                        color: AppColors.gold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedQuest != null
                                ? 'Linked to: ${_selectedQuest!.title}'
                                : 'Link to Active Quest (Proof-of-Action)',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _selectedQuest != null
                                ? 'Verified participant reward: +${_selectedQuest!.xp} XP'
                                : 'Earn XP towards your season level upon verification',
                            style: TextStyle(
                              color: _selectedQuest != null
                                  ? AppColors.gold
                                  : context.colors.textMuted,
                              fontSize: 11,
                              fontWeight: _selectedQuest != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: context.colors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Caption input
            TextField(
              controller: _captionController,
              maxLines: 3,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: _isTextMode
                    ? 'Add further context or notes…'
                    : 'Describe your real-world experience…',
                hintStyle: TextStyle(color: context.colors.textMuted),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.colors.border),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Tag People & Tag Community
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.questBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.group_add, color: context.colors.questBlue),
              ),
              title: Text(
                'Tag People',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _taggedUsers.isEmpty
                    ? 'Mention collaborators or explorers'
                    : _taggedUsers.map((u) => '@$u').join(', '),
                style: TextStyle(
                  color: _taggedUsers.isEmpty
                      ? context.colors.textMuted
                      : context.colors.questBlue,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: context.colors.textMuted,
              ),
              onTap: _showTagPeoplePicker,
            ),
            Divider(color: context.colors.border.withValues(alpha: 0.4), height: 1),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (_selectedCommunity?.accentColor ?? context.colors.emerald)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _selectedCommunity?.icon ?? Icons.groups,
                  color: _selectedCommunity?.accentColor ?? context.colors.emerald,
                ),
              ),
              title: Text(
                'Target Community',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _selectedCommunity != null
                    ? '${_selectedCommunity!.name} • ${_selectedCommunity!.memberCount} members'
                    : 'Tap to select guild / community channel',
                style: TextStyle(
                  color: _selectedCommunity != null
                      ? context.colors.questBlue
                      : context.colors.textMuted,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: context.colors.textMuted,
              ),
              onTap: _showCommunityPicker,
            ),

            const SizedBox(height: 24),

            // 5. Publish Destinations Segmented Selector
            Text(
              'Publish Destinations',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildDestinationPill(
                  icon: Icons.history_toggle_off,
                  label: 'Story',
                  subtitle: '24 hours',
                  isSelected: _shareToStory,
                  onTap: () => setState(() => _shareToStory = !_shareToStory),
                ),
                const SizedBox(width: 8),
                _buildDestinationPill(
                  icon: Icons.dynamic_feed,
                  label: 'Feed',
                  subtitle: 'Permanent',
                  isSelected: _shareToFeed,
                  onTap: () => setState(() => _shareToFeed = !_shareToFeed),
                ),
                const SizedBox(width: 8),
                _buildDestinationPill(
                  icon: Icons.groups_outlined,
                  label: 'Guild',
                  subtitle: _selectedCommunity?.name ?? 'Select',
                  isSelected: _shareToCommunities,
                  onTap: () {
                    setState(() => _shareToCommunities = !_shareToCommunities);
                    if (_shareToCommunities && _selectedCommunity == null) {
                      _showCommunityPicker();
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 36),

            // 6. Share Action Button with Inline Progress
            if (_isUploading)
              Column(
                children: [
                  LinearProgressIndicator(
                    backgroundColor: context.colors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(context.colors.questBlue),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _uploadStatus,
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.questBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _isUploading
                    ? null
                    : () async {
                        final destinations = <String>[];
                        if (_shareToFeed) destinations.add('feed');
                        if (_shareToStory) destinations.add('story');
                        if (_shareToCommunities) {
                          if (_selectedCommunity != null) {
                            destinations.add('community');
                          } else {
                            HapticFeedback.heavyImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Please select a community to share with.',
                                ),
                                backgroundColor: context.colors.crimson,
                              ),
                            );
                            _showCommunityPicker();
                            return;
                          }
                        }

                        if (destinations.isEmpty) {
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Please choose at least one destination (Story, Feed, or Guild).',
                              ),
                              backgroundColor: context.colors.crimson,
                            ),
                          );
                          return;
                        }

                        HapticFeedback.heavyImpact();
                        setState(() {
                          _isUploading = true;
                          _uploadStatus = _isTextMode
                              ? 'Publishing text insight…'
                              : 'Preparing media…';
                          _usedFallback = false;
                        });

                        void updateStatus(String msg) {
                          if (mounted) setState(() => _uploadStatus = msg);
                          AppNotificationService().showUploadProgress(msg);
                        }

                        try {
                          String? mediaUrl;
                          String? muxPlaybackId;
                          String? muxAssetId;
                          final supabase = Supabase.instance.client;

                          // Only upload media if not pure text mode
                          if (!_isTextMode &&
                              _effectiveMediaPath != null &&
                              _effectiveMediaPath!.isNotEmpty) {
                            if (kIsWeb) {
                              Uint8List? bytes;
                              try {
                                final xFile = XFile(_effectiveMediaPath!);
                                bytes = await xFile.readAsBytes();
                              } catch (err) {
                                debugPrint('Web bytes error: $err');
                              }

                              if (bytes != null && bytes.isNotEmpty) {
                                if (_isCurrentVideo) {
                                  final result =
                                      await MediaServiceGateway.uploadVideoBytes(
                                    bytes,
                                    MediaPurpose.feed,
                                    onStatus: updateStatus,
                                  );
                                  if (result != null) {
                                    _usedFallback = result.usedFallback;
                                    if (result.usedFallback) {
                                      mediaUrl = result.url;
                                    } else {
                                      muxPlaybackId = result.url;
                                      muxAssetId = result.assetId;
                                    }
                                  } else {
                                    mediaUrl = _effectiveMediaPath;
                                  }
                                } else {
                                  updateStatus('Uploading image…');
                                  mediaUrl =
                                      await MediaServiceGateway.uploadImageBytes(
                                    bytes,
                                    MediaPurpose.feed,
                                  );
                                  mediaUrl ??= _effectiveMediaPath;
                                }
                              } else {
                                mediaUrl = _effectiveMediaPath;
                              }
                            } else {
                              if (!_effectiveMediaPath!.startsWith('http')) {
                                final file = File(_effectiveMediaPath!);
                                if (_isCurrentVideo) {
                                  final result =
                                      await MediaServiceGateway.uploadVideo(
                                    file,
                                    MediaPurpose.feed,
                                    onStatus: updateStatus,
                                  );
                                  if (result != null) {
                                    _usedFallback = result.usedFallback;
                                    if (result.usedFallback) {
                                      mediaUrl = result.url;
                                    } else {
                                      muxPlaybackId = result.url;
                                      muxAssetId = result.assetId;
                                    }
                                  } else {
                                    mediaUrl = _effectiveMediaPath;
                                  }
                                } else {
                                  updateStatus('Uploading image…');
                                  mediaUrl =
                                      await MediaServiceGateway.uploadImage(
                                    file,
                                    MediaPurpose.feed,
                                  );
                                  mediaUrl ??= _effectiveMediaPath;
                                }
                              } else {
                                mediaUrl = _effectiveMediaPath;
                              }
                            }

                            mediaUrl ??= _effectiveMediaPath;
                          }

                          updateStatus('Publishing experience…');
                          List<dynamic> videosJson = [];
                          bool publishSucceeded = false;

                          try {
                            final res = await supabase.functions.invoke(
                              'publish-experience',
                              body: {
                                'media_url': mediaUrl,
                                'mux_playback_id': muxPlaybackId,
                                'mux_asset_id': muxAssetId,
                                'caption': _captionController.text.trim(),
                                'destinations': destinations,
                                'community_id': _shareToCommunities
                                    ? _selectedCommunity?.id
                                    : null,
                                'quest_id': _selectedQuest?.id,
                              },
                            );

                            final data = res.data;
                            if (res.status < 400 && data != null && data['success'] == true) {
                              videosJson = data['videos'] ?? [];
                              publishSucceeded = true;
                            } else if (data != null && data['error'] != null) {
                              debugPrint('[ShareExperience] publish-experience backend notice: ${data['error']}');
                            }
                          } catch (invokeErr) {
                            debugPrint('[ShareExperience] publish-experience invocation note: $invokeErr');
                          }

                          // If edge function returned persisted videos, map them; otherwise use local optimistic fallback
                          if (publishSucceeded && videosJson.isNotEmpty) {
                            if (_shareToFeed) {
                              final feedVideoJson = videosJson.firstWhere(
                                (v) => v['video_type'] == 'feed',
                                orElse: () => null,
                              );
                              if (feedVideoJson != null) {
                                try {
                                  final newFeedVideo = CreatorVideo.fromJson(
                                    feedVideoJson,
                                  );
                                  ref
                                      .read(feedControllerProvider)
                                      .insertVideoTop(newFeedVideo);
                                } catch (_) {}
                              }
                            }

                            if (_shareToStory) {
                              final storyJson = videosJson.firstWhere(
                                (v) => v['video_type'] == 'story',
                                orElse: () => null,
                              );
                              if (storyJson != null) {
                                try {
                                  final newStory = StoryItem.fromJson(
                                    storyJson,
                                  );
                                  ref
                                      .read(storiesProvider.notifier)
                                      .addStoryLocally(newStory);
                                } catch (_) {}
                              }
                            }
                          } else {
                            // Offline / Guest / Local Fallback: Optimistically insert locally so content is never lost
                            final userProfile = ref.read(userProvider).value;
                            final currentUserId = supabase.auth.currentUser?.id ?? 'guest';
                            final currentUsername = userProfile?.username ?? userProfile?.name ?? 'Explorer';
                            final currentAvatar = userProfile?.avatarUrl;
                            final postTitle = _captionController.text.trim().isNotEmpty
                                ? _captionController.text.trim().split('\n').first
                                : 'New Experience';
                            final postDesc = _captionController.text.trim();
                            final finalMedia = mediaUrl ??
                                (muxPlaybackId != null
                                    ? 'https://stream.mux.com/$muxPlaybackId.m3u8'
                                    : (_effectiveMediaPath ?? ''));

                            if (_shareToFeed) {
                              try {
                                final localFeedVideo = CreatorVideo(
                                  id: 'feed_${DateTime.now().millisecondsSinceEpoch}',
                                  creatorId: currentUserId,
                                  creatorUsername: currentUsername,
                                  creatorAvatarUrl: currentAvatar,
                                  videoUrl: finalMedia,
                                  thumbnailUrl: finalMedia,
                                  title: postTitle,
                                  description: postDesc,
                                  viewCount: 1,
                                  likeCount: 0,
                                  commentCount: 0,
                                  shareCount: 0,
                                  createdAt: DateTime.now(),
                                  engagementScore: 1.0,
                                  durationSeconds: 15,
                                  muxPlaybackId: muxPlaybackId,
                                );
                                ref
                                    .read(feedControllerProvider)
                                    .insertVideoTop(localFeedVideo);
                              } catch (err) {
                                debugPrint('[ShareExperience] Local feed insert note: $err');
                              }
                            }

                            if (_shareToStory) {
                              try {
                                final localStory = StoryItem(
                                  id: 'story_${DateTime.now().millisecondsSinceEpoch}',
                                  authorName: currentUsername,
                                  authorAvatar: currentAvatar,
                                  caption: postDesc,
                                  videoUrl: finalMedia,
                                  muxPlaybackId: muxPlaybackId,
                                  createdAt: DateTime.now(),
                                  isMe: true,
                                );
                                ref
                                    .read(storiesProvider.notifier)
                                    .addStoryLocally(localStory);
                              } catch (err) {
                                debugPrint('[ShareExperience] Local story insert note: $err');
                              }
                            }
                          }

                          // Award Quest XP if linked
                          if (_selectedQuest != null) {
                            try {
                              await ref
                                  .read(userProvider.notifier)
                                  .addXp(_selectedQuest!.xp);
                            } catch (_) {}
                          }

                          await AppNotificationService().showUploadComplete(
                            usedFallback: _usedFallback,
                          );

                          if (!context.mounted) return;
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _selectedQuest != null
                                    ? '✅ Published & +${_selectedQuest!.xp} XP Awarded!'
                                    : _usedFallback
                                    ? '✅ Shared via Cloudinary backup!'
                                    : '✅ Experience Shared Successfully!',
                              ),
                              backgroundColor: context.colors.emerald,
                            ),
                          );
                          context.go('/home');
                        } catch (e) {
                          await AppNotificationService().showUploadFailed();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error sharing experience: $e'),
                              backgroundColor: context.colors.crimson,
                            ),
                          );
                        } finally {
                          if (context.mounted) {
                            setState(() {
                              _isUploading = false;
                            });
                          }
                        }
                      },
                child: Text(
                  _selectedQuest != null
                      ? 'Publish & Verify Quest (+${_selectedQuest!.xp} XP)'
                      : 'Share Experience Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
