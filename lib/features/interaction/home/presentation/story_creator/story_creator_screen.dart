import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/interaction/home/data/stories_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class StoryCreatorScreen extends ConsumerStatefulWidget {
  const StoryCreatorScreen({super.key});

  @override
  ConsumerState<StoryCreatorScreen> createState() => _StoryCreatorScreenState();
}

class _StoryCreatorScreenState extends ConsumerState<StoryCreatorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int _selectedGradientIndex = 0;
  bool _isSpoiler = false;
  bool _revealedInPreview = false;
  String _selectedCommunityId = '1';

  final List<List<Color>> _gradientPresets = [
    [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
    [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
    [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
    [Color(0xFFD97706), Color(0xFFF59E0B), Color(0xFFFBBF24)],
    [Color(0xFFE11D48), Color(0xFFF43F5E), Color(0xFFFB7185)],
    [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _publishStory() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter both a title and story content'),
          backgroundColor: context.colors.crimson,
        ),
      );
      return;
    }

    final user = (ref.read(userProvider).value ?? UserState.initial());
    final newStory = StoryItem(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      authorName: user.name,
      authorAvatar:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      timeAgo: 'Just now',
      title: title,
      content: content,
      isSpoiler: _isSpoiler,
      isSeen: false,
    );

    ref.read(storiesProvider.notifier).addStory(newStory);
    ref.read(userProvider.notifier).addXp(50);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: context.colors.card,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: context.colors.emerald),
            SizedBox(width: 10),
            Text('Story published to community reel! +50 XP'),
          ],
        ),
      ),
    );

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final communitiesStateAsync = ref.watch(communitiesProvider);
    final communities = communitiesStateAsync.value?.communities ?? [];
    final selectedColors = _gradientPresets[_selectedGradientIndex];

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Story & Broadcast Studio',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.questBlue,
                foregroundColor: context.colors.textPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              icon: Icon(Icons.send_rounded, size: 16),
              label: Text(
                'Publish',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: _publishStory,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Story Preview Canvas
            Text(
              'LIVE STORY CANVAS PREVIEW',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10),

            AspectRatio(
              aspectRatio: 9 / 12,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: selectedColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: selectedColors.first.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar in Preview
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: context.colors.textPrimary24,
                          child: Text(
                            (ref.read(userProvider).value ??
                                    UserState.initial())
                                .initials,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (ref.read(userProvider).value ??
                                      UserState.initial())
                                  .name,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Just now',
                              style: TextStyle(
                                color: context.colors.textPrimary70,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        if (_isSpoiler)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.background45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_off,
                                  color: context.colors.gold,
                                  size: 12,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'SPOILER',
                                  style: TextStyle(
                                    color: context.colors.gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Main Body with Optional Spoiler Blur
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (_isSpoiler) {
                          setState(() {
                            _revealedInPreview = !_revealedInPreview;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.background.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleController.text.isEmpty
                                  ? 'Your Announcement Headline'
                                  : _titleController.text,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (_isSpoiler && !_revealedInPreview)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                alignment: Alignment.center,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.touch_app,
                                      color: context.colors.textPrimary70,
                                      size: 24,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap to Reveal Spoiler Content',
                                      style: TextStyle(
                                        color: context.colors.textPrimary70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                _contentController.text.isEmpty
                                    ? 'Write your broadcast update, alpha, or community highlight here...'
                                    : _contentController.text,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.textPrimary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            communities
                                .firstWhere(
                                  (c) => c.id == _selectedCommunityId,
                                  orElse: () => communities.first,
                                )
                                .name,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.bolt, color: context.colors.gold, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '+50 XP',
                              style: TextStyle(
                                color: context.colors.gold,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Color Palette Selector
            Text(
              'CANVAS THEME PALETTES',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _gradientPresets.length,
                separatorBuilder: (context, index) => SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedGradientIndex;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedGradientIndex = index;
                      });
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: _gradientPresets[index],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.textPrimary
                              : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 24),

            // Controls & Inputs
            Text(
              'STORY DETAILS',
              style: TextStyle(
                color: context.colors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 10),

            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Story Title / Headline',
                labelStyle: TextStyle(color: context.colors.textMuted),
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
              ),
            ),
            SizedBox(height: 12),

            TextField(
              controller: _contentController,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Story Content & Highlights',
                labelStyle: TextStyle(color: context.colors.textMuted),
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
              ),
            ),
            SizedBox(height: 16),

            // Guild Target Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups,
                    color: context.colors.questBlue,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Target Guild:',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 13),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCommunityId,
                        dropdownColor: context.colors.card,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        items: communities.map((c) {
                          return DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCommunityId = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Spoiler Tag Switcher
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_off,
                    color: context.colors.gold,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tag as Spoiler / Secret Alpha',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Adds tap-to-reveal blur until viewed',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSpoiler,
                    activeThumbColor: context.colors.gold,
                    onChanged: (val) {
                      setState(() {
                        _isSpoiler = val;
                        _revealedInPreview = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
