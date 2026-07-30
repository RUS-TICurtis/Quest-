import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'community_detail_screen.dart';

// Mock data models
class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int memberCount;
  final bool isJoined;
  final Color accentColor;
  final IconData icon;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.memberCount,
    required this.isJoined,
    required this.accentColor,
    required this.icon,
  });
}

final _mockCommunities = [
  CommunityModel(id: '1', name: 'Flutter Builders', description: 'A community for Flutter developers of all skill levels.', category: 'Technology', memberCount: 2340, isJoined: true, accentColor: AppColors.questBlue, icon: Icons.phone_android),
  CommunityModel(id: '2', name: 'Startup Founders', description: 'Connecting early-stage founders, mentors, and investors.', category: 'Business', memberCount: 891, isJoined: true, accentColor: AppColors.emerald, icon: Icons.rocket_launch_outlined),
  CommunityModel(id: '3', name: 'Design Systems', description: 'Typography, color, motion, and component design.', category: 'Design', memberCount: 1204, isJoined: false, accentColor: AppColors.auroraPurple, icon: Icons.palette_outlined),
  CommunityModel(id: '4', name: 'Local Run Club', description: 'Weekly group runs in the city. All paces welcome.', category: 'Fitness', memberCount: 543, isJoined: false, accentColor: AppColors.amber, icon: Icons.directions_run),
  CommunityModel(id: '5', name: 'AI & Machine Learning', description: 'Papers, projects, and practical AI discussions.', category: 'Technology', memberCount: 5120, isJoined: false, accentColor: AppColors.skyBlue, icon: Icons.psychology_outlined),
  CommunityModel(id: '6', name: 'City Photographers', description: 'Share urban photography and join city photo walks.', category: 'Arts', memberCount: 376, isJoined: true, accentColor: AppColors.crimson, icon: Icons.photo_camera_outlined),
];

final _categories = ['All', 'Technology', 'Business', 'Design', 'Fitness', 'Arts'];

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CommunityModel> get _filtered {
    return _mockCommunities.where((c) {
      final matchesCategory = _selectedCategory == 'All' || c.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final joined = _mockCommunities.where((c) => c.isJoined).toList();
    final discover = _filtered.where((c) => !c.isJoined).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Communities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Community',
            onPressed: () => _showCreateSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search communities...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                        onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                      )
                    : null,
              ),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.questBlue : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? AppColors.questBlue : AppColors.border),
                    ),
                    child: Text(cat, style: TextStyle(color: selected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                );
              },
            ),
          ),

          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                if (joined.isNotEmpty && _searchQuery.isEmpty && _selectedCategory == 'All') ...[
                  _sectionHeader('Your Communities', '${joined.length}'),
                  const SizedBox(height: 10),
                  ...joined.map((c) => _communityCard(c, context)),
                  const SizedBox(height: 24),
                ],
                if (discover.isNotEmpty) ...[
                  _sectionHeader('Discover', '${discover.length}'),
                  const SizedBox(height: 10),
                  ...discover.map((c) => _communityCard(c, context)),
                ],
                if (_filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        const Icon(Icons.people_outline, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 16),
                        const Text('No communities found', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Try adjusting your search or filters.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ],
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String count) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Text(count, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _communityCard(CommunityModel c, BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CommunityDetailScreen(community: c))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: c.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(c.icon, color: c.accentColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white))),
                      if (c.isJoined)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.emerald.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                          child: const Text('Joined', style: TextStyle(color: AppColors.emerald, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(c.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${_formatCount(c.memberCount)} members', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.border)),
                        child: Text(c.category, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return '$count';
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Community', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('Start a space for people who share your interests.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 20),
            const TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(hintText: 'Community name...'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Create'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
