import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/core/media/media_service_gateway.dart';
import 'package:quest/core/media/media_purpose.dart';
import 'package:quest/core/services/app_notification_service.dart';
import 'package:quest/features/interaction/home/data/stories_provider.dart';
import 'package:quest/shared/models/creator_video.dart';
import 'package:quest/features/interaction/feed/data/feed_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';

class ShareExperienceScreen extends ConsumerStatefulWidget {
  final String? mediaPath;
  const ShareExperienceScreen({super.key, this.mediaPath});

  @override
  ConsumerState<ShareExperienceScreen> createState() =>
      _ShareExperienceScreenState();
}

class _ShareExperienceScreenState extends ConsumerState<ShareExperienceScreen> {
  bool _shareToStory = true;
  bool _shareToFeed = false;
  bool _shareToCommunities = false;
  Community? _selectedCommunity;
  final List<String> _taggedUsers = [];
  bool _isUploading = false;
  String _uploadStatus = 'Preparing…';
  bool _usedFallback = false;
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoPlayerController;

  bool _isVideo(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi') ||
        lowerPath.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    if (widget.mediaPath != null && _isVideo(widget.mediaPath!)) {
      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.mediaPath!),
        );
      } else {
        _videoPlayerController = VideoPlayerController.file(
          File(widget.mediaPath!),
        );
      }
      _videoPlayerController!.initialize().then((_) {
        setState(() {});
        _videoPlayerController!.setLooping(true);
        _videoPlayerController!.play();
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () => context.pop(),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview Container
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
                image:
                    widget.mediaPath != null &&
                        !_isVideo(widget.mediaPath!) &&
                        !widget.mediaPath!.startsWith('http')
                    ? DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(widget.mediaPath!) as ImageProvider
                            : FileImage(File(widget.mediaPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.mediaPath == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 48,
                              color: context.colors.textMuted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Media Preview',
                              style: TextStyle(color: context.colors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : widget.mediaPath!.startsWith('http')
                    ? Center(
                        child: Text(
                          widget.mediaPath!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : _isVideo(widget.mediaPath!) &&
                          _videoPlayerController != null &&
                          _videoPlayerController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: VideoPlayer(_videoPlayerController!),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Caption input
            TextField(
              controller: _captionController,
              maxLines: 3,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Add a caption...',
                hintStyle: TextStyle(color: context.colors.textMuted),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tagging options
            ListTile(
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
                    ? 'Tag people by username'
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
                size: 16,
                color: context.colors.textMuted,
              ),
              onTap: _showTagPeoplePicker,
            ),
            ListTile(
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
                'Share to Communities',
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                _selectedCommunity != null
                    ? '${_selectedCommunity!.name} • ${_selectedCommunity!.memberCount} members'
                    : 'Tap to select a community destination',
                style: TextStyle(
                  color: _selectedCommunity != null
                      ? context.colors.questBlue
                      : context.colors.textMuted,
                  fontSize: 12,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.colors.textMuted,
              ),
              onTap: _showCommunityPicker,
            ),

            const SizedBox(height: 24),
            Text(
              'Post To',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              title: Text(
                'My Story',
                style: TextStyle(color: context.colors.textPrimary),
              ),
              subtitle: Text(
                'Visible for 24 hours',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
              value: _shareToStory,
              activeThumbColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _shareToStory = val),
            ),
            SwitchListTile(
              title: Text(
                'Main Feed',
                style: TextStyle(color: context.colors.textPrimary),
              ),
              subtitle: Text(
                'Visible to all explorers in the feed',
                style: TextStyle(color: context.colors.textMuted, fontSize: 12),
              ),
              value: _shareToFeed,
              activeThumbColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _shareToFeed = val),
            ),
            SwitchListTile(
              title: Text(
                'Communities',
                style: TextStyle(color: context.colors.textPrimary),
              ),
              subtitle: Text(
                _selectedCommunity != null
                    ? 'Posting to ${_selectedCommunity!.name}'
                    : 'Requires selecting a community',
                style: TextStyle(
                  color: _selectedCommunity != null
                      ? context.colors.questBlue
                      : context.colors.textMuted,
                  fontSize: 12,
                ),
              ),
              value: _shareToCommunities,
              activeThumbColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() => _shareToCommunities = val);
                if (val && _selectedCommunity == null) {
                  _showCommunityPicker();
                }
              },
            ),

            const SizedBox(height: 40),

            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.questBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                                'Please choose at least one destination (Story, Feed, or Community).',
                              ),
                              backgroundColor: context.colors.crimson,
                            ),
                          );
                          return;
                        }

                        HapticFeedback.heavyImpact();
                        setState(() {
                          _isUploading = true;
                          _uploadStatus = 'Preparing media…';
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

                          if (widget.mediaPath != null &&
                              widget.mediaPath!.isNotEmpty) {
                            if (kIsWeb) {
                              // Web platform: Read bytes from XFile or blob URL
                              Uint8List? bytes;
                              try {
                                final xFile = XFile(widget.mediaPath!);
                                bytes = await xFile.readAsBytes();
                              } catch (err) {
                                debugPrint(
                                  'Could not read bytes via XFile on Web: $err',
                                );
                              }

                              if (bytes != null && bytes.isNotEmpty) {
                                if (_isVideo(widget.mediaPath!)) {
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
                                  }
                                } else {
                                  updateStatus('Uploading image…');
                                  mediaUrl =
                                      await MediaServiceGateway.uploadImageBytes(
                                        bytes,
                                        MediaPurpose.feed,
                                      );
                                }
                              } else {
                                mediaUrl = widget.mediaPath;
                              }
                            } else {
                              // Native mobile / desktop
                              if (!widget.mediaPath!.startsWith('http')) {
                                final file = File(widget.mediaPath!);
                                if (_isVideo(widget.mediaPath!)) {
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
                                  }
                                } else {
                                  updateStatus('Uploading image…');
                                  mediaUrl =
                                      await MediaServiceGateway.uploadImage(
                                        file,
                                        MediaPurpose.feed,
                                      );
                                }
                              } else {
                                mediaUrl = widget.mediaPath;
                              }
                            }

                            if (mediaUrl == null && muxPlaybackId == null) {
                              throw Exception(
                                'Media upload failed. Please check network connection and try again.',
                              );
                            }
                          }

                          updateStatus('Publishing experience…');
                          final res = await supabase.functions.invoke(
                            'publish-experience',
                            body: {
                              'media_url': mediaUrl,
                              'mux_playback_id': muxPlaybackId,
                              'mux_asset_id': muxAssetId,
                              'caption': _captionController.text.trim(),
                              'destinations': destinations,
                              'community_id':
                                  _shareToCommunities
                                      ? _selectedCommunity?.id
                                      : null,
                            },
                          );

                          final data = res.data;
                          if (res.status >= 400 ||
                              (data != null && data['error'] != null)) {
                            throw Exception(
                              data?['error'] ??
                                  'Server rejected experience publication (HTTP ${res.status})',
                            );
                          }

                          if (data != null && data['success'] == true) {
                            final List<dynamic> videosJson =
                                data['videos'] ?? [];

                            // Optimistic Updates
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
                          }

                          await AppNotificationService().showUploadComplete(
                            usedFallback: _usedFallback,
                          );

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _usedFallback
                                    ? '✅ Shared via Cloudinary backup!'
                                    : '✅ Experience Shared!',
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
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _uploadStatus,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Share Now',
                        style: TextStyle(
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
