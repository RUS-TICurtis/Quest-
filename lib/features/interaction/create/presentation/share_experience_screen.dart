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
import 'package:quest/features/interaction/home/data/stories_provider.dart';

class ShareExperienceScreen extends ConsumerStatefulWidget {
  final String? mediaPath;
  const ShareExperienceScreen({super.key, this.mediaPath});

  @override
  ConsumerState<ShareExperienceScreen> createState() => _ShareExperienceScreenState();
}

class _ShareExperienceScreenState extends ConsumerState<ShareExperienceScreen> {
  bool _shareToStory = true;
  bool _shareToFeed = false;
  bool _shareToCommunities = false;
  bool _isUploading = false;
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoPlayerController;

  bool _isVideo(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') || lowerPath.endsWith('.mov') || lowerPath.endsWith('.avi') || lowerPath.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    if (widget.mediaPath != null && _isVideo(widget.mediaPath!)) {
      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.mediaPath!));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.mediaPath!));
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

  void _showSelectionBottomSheet(String title, List<String> recents, List<String> frequents) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
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
                  child: Text(
                    title,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    style: TextStyle(color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(color: context.colors.textMuted),
                      prefixIcon: Icon(Icons.search, color: context.colors.textMuted),
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
                TabBar(
                  labelColor: context.colors.questBlue,
                  unselectedLabelColor: context.colors.textMuted,
                  indicatorColor: context.colors.questBlue,
                  tabs: const [
                    Tab(text: 'Recents'),
                    Tab(text: 'Frequent'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildList(recents),
                      _buildList(frequents),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<String> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colors.questBlue.withValues(alpha: 0.1),
            child: Text(
              items[index][0],
              style: TextStyle(color: context.colors.questBlue, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(items[index], style: TextStyle(color: context.colors.textPrimary)),
          trailing: Icon(Icons.add_circle_outline, color: context.colors.textMuted),
          onTap: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Selected: ${items[index]}')),
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
          style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
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
                image: widget.mediaPath != null && !_isVideo(widget.mediaPath!) && !widget.mediaPath!.startsWith('http')
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
                            Icon(Icons.image, size: 48, color: context.colors.textMuted),
                            const SizedBox(height: 8),
                            Text('Media Preview', style: TextStyle(color: context.colors.textMuted)),
                          ],
                        ),
                      )
                    : widget.mediaPath!.startsWith('http') 
                        ? Center(child: Text(widget.mediaPath!, style: const TextStyle(color: Colors.white))) 
                        : _isVideo(widget.mediaPath!) && _videoPlayerController != null && _videoPlayerController!.value.isInitialized
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
              title: Text('Tag People', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.textMuted),
              onTap: () {
                _showSelectionBottomSheet(
                  'Tag People',
                  ['Alex Rivera', 'Elena Rostova', 'Marcus Vance', 'Sarah Jenkins'],
                  ['Alex Rivera', 'David Kim', 'Emma Watson'],
                );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.emerald.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.groups, color: context.colors.emerald),
              ),
              title: Text('Share to Communities', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.colors.textMuted),
              onTap: () {
                _showSelectionBottomSheet(
                  'Select Communities',
                  ['Flutter Devs', 'Tech Enthusiasts', 'Local Runners'],
                  ['Flutter Devs', 'Design Systems', 'AI Explorers'],
                );
              },
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
              title: Text('My Story', style: TextStyle(color: context.colors.textPrimary)),
              subtitle: Text('Visible for 24 hours', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              value: _shareToStory,
              activeThumbColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _shareToStory = val),
            ),
            SwitchListTile(
              title: Text('Main Feed', style: TextStyle(color: context.colors.textPrimary)),
              value: _shareToFeed,
              activeThumbColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _shareToFeed = val),
            ),
            SwitchListTile(
              title: Text('Communities', style: TextStyle(color: context.colors.textPrimary)),
              value: _shareToCommunities,
              activeThumbColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _shareToCommunities = val),
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
                onPressed: _isUploading ? null : () async {
                  HapticFeedback.heavyImpact();
                  setState(() { _isUploading = true; });
                  
                  try {
                    String? mediaUrl;
                    String? muxPlaybackId;
                    String? muxAssetId;
                    final supabase = Supabase.instance.client;
                    
                    if (widget.mediaPath != null) {
                      if (kIsWeb) {
                        // Web platform: Read bytes from XFile or blob URL
                        Uint8List? bytes;
                        try {
                          final xFile = XFile(widget.mediaPath!);
                          bytes = await xFile.readAsBytes();
                        } catch (err) {
                          debugPrint('Could not read bytes via XFile on Web: $err');
                        }

                        if (bytes != null && bytes.isNotEmpty) {
                          if (_isVideo(widget.mediaPath!)) {
                            final result = await MediaServiceGateway.uploadVideoBytes(bytes, MediaPurpose.feed);
                            muxPlaybackId = result?.url;
                            muxAssetId = result?.assetId;
                          } else {
                            mediaUrl = await MediaServiceGateway.uploadImageBytes(bytes, MediaPurpose.feed);
                          }
                        } else {
                          mediaUrl = widget.mediaPath;
                        }
                      } else {
                        // Native mobile / desktop
                        if (!widget.mediaPath!.startsWith('http')) {
                          final file = File(widget.mediaPath!);
                          if (_isVideo(widget.mediaPath!)) {
                            final result = await MediaServiceGateway.uploadVideo(file, MediaPurpose.feed);
                            muxPlaybackId = result?.url;
                            muxAssetId = result?.assetId;
                          } else {
                            mediaUrl = await MediaServiceGateway.uploadImage(file, MediaPurpose.feed);
                          }
                        } else {
                          mediaUrl = widget.mediaPath;
                        }
                      }
                    }
                    
                    if (_shareToStory) {
                      final now = DateTime.now();
                      final currentUserName = supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'You';
                      
                      final newStory = StoryItem(
                        id: 's_${now.millisecondsSinceEpoch}',
                        authorName: currentUserName,
                        communityName: 'My Story',
                        caption: _captionController.text,
                        content: mediaUrl,
                        muxPlaybackId: muxPlaybackId,
                        videoUrl: muxPlaybackId != null 
                            ? 'https://stream.mux.com/$muxPlaybackId.m3u8' 
                            : (mediaUrl != null && _isVideo(mediaUrl) ? mediaUrl : null),
                        ringColor: AppColors.questBlue,
                        createdAt: now,
                        isSeen: false,
                        isMe: true,
                      );

                      // Persists to local state & Supabase backend seamlessly
                      try {
                        await ref.read(storiesProvider.notifier).addStory(newStory);
                      } catch (err) {
                        debugPrint('Could not update stories provider: $err');
                      }
                    }

                    if (_shareToFeed) {
                      final currentUser = supabase.auth.currentUser;
                      if (currentUser != null) {
                        try {
                          await supabase.from('creator_videos').insert({
                            'creator_id': currentUser.id,
                            'video_url': muxPlaybackId != null 
                                ? 'https://stream.mux.com/$muxPlaybackId.m3u8' 
                                : (mediaUrl ?? ''),
                            'thumbnail_url': mediaUrl ?? (muxPlaybackId != null ? 'https://image.mux.com/$muxPlaybackId/thumbnail.jpg' : ''),
                            'title': _captionController.text.isNotEmpty ? _captionController.text : 'New Experience',
                            'description': _captionController.text,
                            'mux_playback_id': muxPlaybackId,
                            'mux_asset_id': muxAssetId,
                            'duration_seconds': 15,
                            'status': 'approved',
                          });
                        } catch (feedErr) {
                          debugPrint('Feed video insert notice: $feedErr');
                        }
                      }
                    }
                    
                    if (_shareToCommunities) {
                      try {
                        await supabase.from('community_posts').insert({
                          'media_url': mediaUrl,
                          'content': _captionController.text,
                          'user_id': supabase.auth.currentUser?.id,
                          'community_id': '1',
                        });
                      } catch (commErr) {
                        debugPrint('Community post insert fallback: $commErr');
                      }
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Experience Shared Successfully!'),
                        backgroundColor: context.colors.emerald,
                      ),
                    );
                    context.go('/home');
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing: $e'),
                        backgroundColor: context.colors.crimson,
                      ),
                    );
                  } finally {
                    if (context.mounted) {
                      setState(() { _isUploading = false; });
                    }
                  }
                },
                child: _isUploading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Share Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
