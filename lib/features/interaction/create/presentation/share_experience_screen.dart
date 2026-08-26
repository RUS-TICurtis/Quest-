import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class ShareExperienceScreen extends StatefulWidget {
  const ShareExperienceScreen({super.key});

  @override
  State<ShareExperienceScreen> createState() => _ShareExperienceScreenState();
}

class _ShareExperienceScreenState extends State<ShareExperienceScreen> {
  bool _shareToStory = true;
  bool _shareToFeed = false;
  bool _shareToCommunities = false;
  final TextEditingController _captionController = TextEditingController();

  @override
  void dispose() {
    _captionController.dispose();
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
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: context.colors.textMuted),
                    SizedBox(height: 8),
                    Text('Media Preview', style: TextStyle(color: context.colors.textMuted)),
                  ],
                ),
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
              activeColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _shareToStory = val),
            ),
            SwitchListTile(
              title: Text('Main Feed', style: TextStyle(color: context.colors.textPrimary)),
              value: _shareToFeed,
              activeColor: context.colors.questBlue,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) => setState(() => _shareToFeed = val),
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
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Experience Shared Successfully!'),
                      backgroundColor: context.colors.emerald,
                    ),
                  );
                  context.go('/home');
                },
                child: Text('Share Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
