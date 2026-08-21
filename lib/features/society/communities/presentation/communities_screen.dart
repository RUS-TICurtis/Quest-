import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

final _categories = [
  'All',
  'Technology',
  'Business',
  'Design',
  'Fitness',
  'Arts',
];

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final communitiesStateAsync = ref.watch(communitiesProvider);
    final communitiesState = communitiesStateAsync.value;

    if (communitiesState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.questBlue),
        ),
      );
    }
    final userState = (ref.watch(userProvider).value ?? UserState.initial());

    final allCommunities = communitiesState.filteredCommunities;
    final joined = allCommunities
        .where((c) => userState.joinedCommunityIds.contains(c.id))
        .toList();
    final discover = allCommunities
        .where((c) => !userState.joinedCommunityIds.contains(c.id))
        .toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.questBlue,
        child: Icon(Icons.add, color: context.colors.textPrimary),
        onPressed: () {
          HapticFeedback.lightImpact();
          _showCreateSheet(context);
        },
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  ref.read(communitiesProvider.notifier).setSearchQuery(v),
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search communities...',
                prefixIcon: Icon(
                  Icons.search,
                  color: context.colors.textMuted,
                ),
                suffixIcon: communitiesState.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: context.colors.textMuted,
                          size: 18,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _searchController.clear();
                          ref
                              .read(communitiesProvider.notifier)
                              .setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = communitiesState.selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(communitiesProvider.notifier).setCategory(cat);
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? context.colors.questBlue : context.colors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? context.colors.questBlue
                            : context.colors.border,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: selected
                            ? context.colors.textPrimary
                            : context.colors.textMuted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Discover/Search Layout
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (joined.isNotEmpty &&
                          communitiesState.searchQuery.isEmpty &&
                          communitiesState.selectedCategory == 'All') ...[
                        _sectionHeader('Your Communities', '${joined.length}'),
                        SizedBox(height: 10),
                        ...joined.map((c) => _communityCard(c, true, context)),
                        SizedBox(height: 24),
                      ],
                      if (discover.isNotEmpty) ...[
                        _sectionHeader('Discover', '${discover.length}'),
                        SizedBox(height: 16),
                      ],
                    ]),
                  ),
                ),
                if (discover.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _communityGridCard(
                          discover[index],
                          userState.joinedCommunityIds.contains(discover[index].id),
                          context,
                        ),
                        childCount: discover.length,
                      ),
                    ),
                  ),
                if (allCommunities.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: context.colors.textMuted,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No communities found',
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters.',
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SliverPadding(padding: EdgeInsets.only(bottom: 80)),
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
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.border),
          ),
          child: Text(
            count,
            style: TextStyle(
              color: context.colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _communityGridCard(Community c, bool isJoined, BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/communities/${c.id}');
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      c.accentColor.withValues(alpha: 0.3),
                      c.accentColor.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Center(
                  child: Icon(c.icon, color: c.accentColor, size: 38),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      c.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 12,
                          color: context.colors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatCount(c.memberCount),
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _communityCard(Community c, bool isJoined, BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/communities/${c.id}');
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          children: [
            // Icon badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(c.icon, color: c.accentColor, size: 26),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isJoined)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.emerald.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Joined',
                            style: TextStyle(
                              color: context.colors.emerald,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    c.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 13,
                        color: context.colors.textMuted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${_formatCount(c.memberCount)} members',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Text(
                          c.category,
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              color: context.colors.textMuted,
              size: 20,
            ),
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
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'Technology';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Community',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Start a space for people who share your interests.',
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Community name...',
                  ),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: TextStyle(color: context.colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'What is this community about?',
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  dropdownColor: context.colors.card,
                  style: TextStyle(color: context.colors.textPrimary),
                  decoration: InputDecoration(labelText: 'Category'),
                  items: _categories
                      .where((c) => c != 'All')
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setSheetState(() => category = v ?? 'Technology'),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (nameCtrl.text.trim().isNotEmpty) {
                        final newId =
                            '${DateTime.now().millisecondsSinceEpoch}';
                        final newCommunity = Community(
                          id: newId,
                          name: nameCtrl.text.trim(),
                          description: descCtrl.text.trim().isNotEmpty
                              ? descCtrl.text.trim()
                              : 'Active community group',
                          category: category,
                          memberCount: 1,
                          accentColor: context.colors.questBlue,
                          icon: Icons.groups,
                        );
                        ref
                            .read(communitiesProvider.notifier)
                            .addCommunity(newCommunity);
                        ref
                            .read(userProvider.notifier)
                            .toggleJoinCommunity(newId);
                        Navigator.pop(sheetContext);
                        context.push('/communities/$newId');
                      }
                    },
                    child: Text('Create Community'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
