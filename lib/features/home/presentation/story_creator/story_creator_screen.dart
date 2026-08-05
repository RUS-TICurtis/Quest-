import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../communities/data/communities_provider.dart';
import '../../../profile/data/user_provider.dart';
import '../../data/stories_provider.dart';

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
    [const Color(0xFF6366F1), const Color(0xFFA855F7), const Color(0xFFEC4899)],
    [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF334155)],
    [const Color(0xFF059669), const Color(0xFF10B981), const Color(0xFF34D399)],
    [const Color(0xFFD97706), const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
    [const Color(0xFFE11D48), const Color(0xFFF43F5E), const Color(0xFFFB7185)],
    [const Color(0xFF0284C7), const Color(0xFF0EA5E9), const Color(0xFF38BDF8)],
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
        const SnackBar(
          content: Text('Please enter both a title and story content'),
          backgroundColor: AppColors.crimson,
        ),
      );
      return;
    }

    final user = (ref.read(userProvider).value ?? UserState.initial());
    final newStory = StoryItem(
      id: 'story_${DateTime.now().millisecondsSinceEpoch}',
      authorName: user.name,
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      timeAgo: 'Just now',
      title: title,
      content: content,
      isSpoiler: _isSpoiler,
      isSeen: false,
    );

    ref.read(storiesProvider.notifier).addStory(newStory);
    ref.read(userProvider.notifier).addXp(50);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.card,
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.emerald),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Story & Broadcast Studio',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.questBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text('Publish', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _publishStory,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Story Preview Canvas
            const Text(
              'LIVE STORY CANVAS PREVIEW',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

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
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Bar in Preview
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          child: Text(
                            (ref.read(userProvider).value ?? UserState.initial()).initials,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              (ref.read(userProvider).value ?? UserState.initial()).name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Text(
                              'Just now',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (_isSpoiler)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off, color: AppColors.gold, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'SPOILER',
                                  style: TextStyle(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Main Body with Optional Spoiler Blur
                    GestureDetector(
                      onTap: () {
                        if (_isSpoiler) {
                          setState(() {
                            _revealedInPreview = !_revealedInPreview;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleController.text.isEmpty ? 'Your Announcement Headline' : _titleController.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_isSpoiler && !_revealedInPreview)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                alignment: Alignment.center,
                                child: const Column(
                                  children: [
                                    Icon(Icons.touch_app, color: Colors.white70, size: 24),
                                    SizedBox(height: 6),
                                    Text(
                                      'Tap to Reveal Spoiler Content',
                                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Text(
                                _contentController.text.isEmpty
                                    ? 'Write your broadcast update, alpha, or community highlight here...'
                                    : _contentController.text,
                                style: const TextStyle(
                                  color: Colors.white,
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            communities.firstWhere((c) => c.id == _selectedCommunityId, orElse: () => communities.first).name,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.bolt, color: AppColors.gold, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '+50 XP',
                              style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Color Palette Selector
            const Text(
              'CANVAS THEME PALETTES',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _gradientPresets.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedGradientIndex;
                  return GestureDetector(
                    onTap: () {
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
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: isSelected ? 3 : 0,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Controls & Inputs
            const Text(
              'STORY DETAILS',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Story Title / Headline',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _contentController,
              onChanged: (_) => setState(() {}),
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Story Content & Highlights',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              ),
            ),
            const SizedBox(height: 16),

            // Guild Target Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: AppColors.questBlue, size: 20),
                  const SizedBox(width: 10),
                  const Text('Target Guild:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCommunityId,
                        dropdownColor: AppColors.card,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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
            const SizedBox(height: 16),

            // Spoiler Tag Switcher
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.visibility_off, color: AppColors.gold, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tag as Spoiler / Secret Alpha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Adds tap-to-reveal blur until viewed', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isSpoiler,
                    activeThumbColor: AppColors.gold,
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

