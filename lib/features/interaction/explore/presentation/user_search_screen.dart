import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/explore/data/global_search_repository.dart';
import 'package:quest/features/interaction/explore/data/global_search_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/features/society/events/data/events_provider.dart';

// Alias for seamless routing and backwards compatibility
typedef GlobalSearchScreen = UserSearchScreen;

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late TabController _tabController;

  static const List<String> archetypes = [
    'All',
    'Adventurer',
    'Leader',
    'Organizer',
    'Creator',
    'Connector',
    'Strategist',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        HapticFeedback.selectionClick();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(globalSearchProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.colors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(154),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: (isDark ? context.colors.background : Colors.white)
                  .withValues(alpha: 0.82),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildSearchHeader(context, isDark),
                    _buildTabBar(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Sub-bar for archetype filtering when Users tab is selected
            if (_tabController.index == 1) _buildArchetypeChips(searchState),
            Expanded(
              child: searchState.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: context.colors.questBlue,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(searchState),
                        _buildUsersTab(searchState),
                        _buildQuestsTab(searchState),
                        _buildEventsTab(searchState),
                        _buildCommunitiesTab(searchState),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black)
                    .withValues(alpha: isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.border.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.search,
                      size: 20,
                      color: context.colors.questBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search users, quests, events...",
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: context.colors.textMuted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          ref
                              .read(globalSearchProvider.notifier)
                              .onQueryChanged(value);
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _searchController.clear();
                          ref
                              .read(globalSearchProvider.notifier)
                              .clearSearch();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.colors.textMuted
                                .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _dismissKeyboard();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            child: Text(
              "Close",
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.card.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.4),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: context.colors.questBlue,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.colors.questBlue.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: context.colors.textMuted,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        tabs: const [
          Tab(text: "ALL"),
          Tab(text: "USERS"),
          Tab(text: "QUESTS"),
          Tab(text: "EVENTS"),
          Tab(text: "GUILDS"),
        ],
      ),
    );
  }

  Widget _buildArchetypeChips(GlobalSearchState searchState) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: archetypes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final archetype = archetypes[index];
          final isSelected = searchState.selectedArchetype == archetype;
          return FilterChip(
            selected: isSelected,
            label: Text(archetype == 'All' ? 'All Archetypes' : archetype),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : context.colors.textSecondary,
            ),
            backgroundColor: context.colors.card,
            selectedColor: context.colors.questBlue,
            checkmarkColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? context.colors.questBlue
                  : context.colors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (_) {
              HapticFeedback.lightImpact();
              ref
                  .read(globalSearchProvider.notifier)
                  .setArchetypeFilter(archetype);
            },
          );
        },
      ),
    );
  }

  Widget _buildAllTab(GlobalSearchState searchState) {
    final results = searchState.results;

    if (results.isEmpty) {
      return _buildEmptyState(
        searchState.isTrending
            ? "No trending items found right now."
            : "No matches found for '${searchState.query}'.",
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (searchState.isTrending)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.bolt, color: context.colors.gold, size: 20),
                const SizedBox(width: 6),
                Text(
                  "Trending on Quest",
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

        // Users Section
        if (results.users.isNotEmpty) ...[
          _buildSectionHeader(
            title: "Users",
            count: results.users.length,
            onSeeAll: () {
              HapticFeedback.lightImpact();
              _tabController.animateTo(1);
            },
          ),
          ...results.users
              .take(3)
              .map((user) => _buildUserCard(user)),
          const SizedBox(height: 16),
        ],

        // Quests Section
        if (results.quests.isNotEmpty) ...[
          _buildSectionHeader(
            title: "Quests",
            count: results.quests.length,
            onSeeAll: () {
              HapticFeedback.lightImpact();
              _tabController.animateTo(2);
            },
          ),
          ...results.quests
              .take(3)
              .map((quest) => _buildQuestCard(quest)),
          const SizedBox(height: 16),
        ],

        // Events Section
        if (results.events.isNotEmpty) ...[
          _buildSectionHeader(
            title: "Events",
            count: results.events.length,
            onSeeAll: () {
              HapticFeedback.lightImpact();
              _tabController.animateTo(3);
            },
          ),
          ...results.events
              .take(2)
              .map((event) => _buildEventCard(event)),
          const SizedBox(height: 16),
        ],

        // Communities Section
        if (results.communities.isNotEmpty) ...[
          _buildSectionHeader(
            title: "Guilds & Communities",
            count: results.communities.length,
            onSeeAll: () {
              HapticFeedback.lightImpact();
              _tabController.animateTo(4);
            },
          ),
          ...results.communities
              .take(2)
              .map((c) => _buildCommunityCard(c)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required VoidCallback onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.colors.border),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: [
                Text(
                  "See All",
                  style: TextStyle(
                    color: context.colors.questBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.colors.questBlue,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(GlobalSearchState searchState) {
    final users = searchState.results.users;
    if (users.isEmpty) {
      return _buildEmptyState(
        searchState.isTrending
            ? "No creators or adventurers found."
            : "No users found matching '${searchState.query}'.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: users.length,
      itemBuilder: (context, index) => _buildUserCard(users[index]),
    );
  }

  Widget _buildQuestsTab(GlobalSearchState searchState) {
    final quests = searchState.results.quests;
    if (quests.isEmpty) {
      return _buildEmptyState(
        searchState.isTrending
            ? "No daily quests available."
            : "No quests found matching '${searchState.query}'.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: quests.length,
      itemBuilder: (context, index) => _buildQuestCard(quests[index]),
    );
  }

  Widget _buildEventsTab(GlobalSearchState searchState) {
    final events = searchState.results.events;
    if (events.isEmpty) {
      return _buildEmptyState(
        searchState.isTrending
            ? "No upcoming events found."
            : "No events found matching '${searchState.query}'.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventCard(events[index]),
    );
  }

  Widget _buildCommunitiesTab(GlobalSearchState searchState) {
    final communities = searchState.results.communities;
    if (communities.isEmpty) {
      return _buildEmptyState(
        searchState.isTrending
            ? "No communities discovered."
            : "No communities found matching '${searchState.query}'.",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: communities.length,
      itemBuilder: (context, index) => _buildCommunityCard(communities[index]),
    );
  }

  Widget _buildUserCard(UserSearchResult user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _dismissKeyboard();
            context.push('/profile/${user.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 26,
                  backgroundColor: context.colors.border,
                  backgroundImage: user.avatarUrl != null
                      ? CachedNetworkImageProvider(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          color: context.colors.textSecondary,
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Trust Score Badge
                          _buildTrustBadge(user.trustLevel, user.trustScore),
                        ],
                      ),
                      if (user.username != null)
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      if (user.bio != null && user.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user.bio!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (user.archetypes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Wrap(
                            spacing: 4,
                            children: user.archetypes
                                .take(2)
                                .map((arch) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.colors.auroraPurple
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        arch,
                                        style: TextStyle(
                                          color: context.colors.auroraPurple,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                // Action: Chat Icon
                IconButton(
                  icon: Icon(
                    CupertinoIcons.chat_bubble_2_fill,
                    color: context.colors.questBlue,
                    size: 22,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _dismissKeyboard();
                    context.push('/connect/${user.id}');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(String level, double score) {
    Color badgeColor;
    switch (level.toLowerCase()) {
      case 'platinum':
        badgeColor = context.colors.skyBlue;
        break;
      case 'gold':
        badgeColor = context.colors.gold;
        break;
      case 'silver':
        badgeColor = Colors.grey.shade400;
        break;
      default:
        badgeColor = context.colors.amber;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, size: 10, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(QuestItem quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.star,
              color: context.colors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quest.title,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "+${quest.xp} XP",
                        style: TextStyle(
                          color: context.colors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      quest.isDone ? "Completed" : "Daily Challenge",
                      style: TextStyle(
                        color: quest.isDone
                            ? context.colors.emerald
                            : context.colors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            quest.isDone ? Icons.check_circle : Icons.arrow_forward_ios,
            size: 16,
            color: quest.isDone
                ? context.colors.emerald
                : context.colors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _dismissKeyboard();
            context.push('/events/${event.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event cover
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: context.colors.surface,
                      child: const Center(
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: context.colors.surface,
                      child: Icon(
                        Icons.event,
                        color: context.colors.textMuted,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.questBlue
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.category,
                            style: TextStyle(
                              color: context.colors.questBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: context.colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${event.date} • ${event.time}",
                          style: TextStyle(
                            color: context.colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      event.title,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 13,
                          color: context.colors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            event.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${event.attendeesCount} attending",
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.6),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.lightImpact();
            _dismissKeyboard();
            context.push('/communities/${community.id}');
          },
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: community.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  community.icon,
                  color: community.accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            community.name,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            community.category,
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      community.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${community.memberCount} members",
                      style: TextStyle(
                        color: context.colors.questBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: context.colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.card,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.border),
              ),
              child: Icon(
                CupertinoIcons.search,
                size: 40,
                color: context.colors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
