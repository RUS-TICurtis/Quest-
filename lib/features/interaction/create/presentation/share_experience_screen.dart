import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/core/media/media_service_gateway.dart';
import 'package:quest/core/media/media_purpose.dart';

class ShareExperienceScreen extends StatefulWidget {
  final String? mediaPath;
  const ShareExperienceScreen({super.key, this.mediaPath});

  @override
  State<ShareExperienceScreen> createState() => _ShareExperienceScreenState();
}

class _ShareExperienceScreenState extends State<ShareExperienceScreen> {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DefaultTabController(
          length: 2,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.only(top: 16),
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
                SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TabBar(
                  indicatorColor: context.colors.questBlue,
                  labelColor: context.colors.questBlue,
                  unselectedLabelColor: context.colors.textMuted,
                  dividerColor: context.colors.border,
                  tabs: [
                    Tab(text: 'Recents'),
                    Tab(text: 'Frequent'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Recents Tab
                      ListView.builder(
                        itemCount: recents.length,
                        itemBuilder: (context, index) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.colors.questBlue.withValues(alpha: 0.2),
                            child: Text(recents[index][0], style: TextStyle(color: context.colors.questBlue)),
                          ),
                          title: Text(recents[index], style: TextStyle(color: context.colors.textPrimary)),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Selected ${recents[index]}')),
                            );
                          },
                        ),
                      ),
                      // Frequent Tab
                      ListView.builder(
                        itemCount: frequents.length,
                        itemBuilder: (context, index) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: context.colors.emerald.withValues(alpha: 0.2),
                            child: Text(frequents[index][0], style: TextStyle(color: context.colors.emerald)),
                          ),
                          title: Text(frequents[index], style: TextStyle(color: context.colors.textPrimary)),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Selected ${frequents[index]}')),
                            );
                          },
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Share Experience', style: TextStyle(color: context.colors.textPrimary)),
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview placeholder
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.border),
                image: widget.mediaPath != null && !_isVideo(widget.mediaPath!) && !widget.mediaPath!.startsWith('http')
                    ? DecorationImage(
                        image: kIsWeb ? NetworkImage(widget.mediaPath!) as ImageProvider : FileImage(File(widget.mediaPath!)),
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
                            SizedBox(height: 8),
                            Text('Media Preview', style: TextStyle(color: context.colors.textMuted)),
                          ],
                        ),
                      )
                    : widget.mediaPath!.startsWith('http') 
                        ? Center(child: Text(widget.mediaPath!, style: TextStyle(color: Colors.white))) 
                        : _isVideo(widget.mediaPath!) && _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoPlayerController!.value.aspectRatio,
                                child: VideoPlayer(_videoPlayerController!),
                              )
                            : null,
              ),
            ),
            SizedBox(height: 24),

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
            SizedBox(height: 24),

            // Tagging options
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.questBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person_add, color: context.colors.questBlue),
              ),
              title: Text('Tag People', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
              onTap: () {
                HapticFeedback.lightImpact();
                _showSelectionBottomSheet(
                  'Tag People',
                  ['Alex L.', 'Sarah Chen', 'Michael Doe'],
                  ['Jessica W.', 'David Kim', 'Emma G.'],
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.emerald.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.groups, color: context.colors.emerald),
              ),
              title: Text('Share to Communities', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
              onTap: () {
                HapticFeedback.lightImpact();
                _showSelectionBottomSheet(
                  'Select Communities',
                  ['SF Tech Builders', 'YC Alumni', 'Flutter Devs'],
                  ['Indie Hackers', 'AI Enthusiasts', 'Design Thinkers'],
                );
              },
            ),

            Divider(color: context.colors.border, height: 32),
            
            Text('Post To', style: TextStyle(color: context.colors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            // Share toggles
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
            
            SizedBox(height: 40),
            
            // Share Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.questBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
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
                    
                    if (widget.mediaPath != null && !widget.mediaPath!.startsWith('http')) {
                      File file = File(widget.mediaPath!);
                      if (_isVideo(widget.mediaPath!)) {
                        final result = await MediaServiceGateway.uploadVideo(file, MediaPurpose.feed);
                        muxPlaybackId = result?.url;
                        muxAssetId = result?.assetId;
                      } else {
                        mediaUrl = await MediaServiceGateway.uploadImage(file, MediaPurpose.feed);
                      }
                    }
                    
                    if (_shareToStory) {
                      await supabase.from('stories').insert({
                        'media_url': mediaUrl,
                        'mux_playback_id': muxPlaybackId,
                        'mux_asset_id': muxAssetId,
                        'caption': _captionController.text,
                        'user_id': supabase.auth.currentUser?.id,
                        'timeAgo': 'Just now', // Satisfies legacy NOT NULL DB constraint
                        // Note: authorName is currently NOT NULL in schema, so we provide a fallback
                        'authorName': supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Quest User',
                      });
                    }
                    
                    if (_shareToCommunities) {
                      await supabase.from('community_posts').insert({
                        'media_url': mediaUrl,
                        'content': _captionController.text,
                        'user_id': supabase.auth.currentUser?.id,
                        'community_id': '1', // Hardcoded for prototype
                      });
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Experience Shared Successfully!'),
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
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Share Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
