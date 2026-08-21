import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/quest_icons.dart';
import 'package:quest/features/identity/leaderboard/data/leaderboard_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(leaderboardProvider);
    final state = stateAsync.value;
    final notifier = ref.read(leaderboardProvider.notifier);

    if (state == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(
          child: CircularProgressIndicator(color: context.colors.questBlue),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: context.colors.textPrimary,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      HapticFeedback.lightImpact();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/profile');
                      }
                    },
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SEASON 3: RENAISSANCE',
                          style: TextStyle(
                            color: context.colors.gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Guild & Archetype Standings',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: context.colors.gold.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.timer, color: context.colors.gold, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '4d left',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Navigation
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: ['Archetypes', 'Guild Leagues'].map((tab) {
                  final isSelected = tab == state.selectedTab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        HapticFeedback.selectionClick();
                        notifier.setTab(tab);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.colors.questBlue.withValues(alpha: 0.2)
                              : context.colors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? context.colors.questBlue
                                : context.colors.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isSelected
                                ? context.colors.textPrimary
                                : context.colors.textMuted,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 12),

            // Archetype Filter Bar (when on Archetypes tab)
            if (state.selectedTab == 'Archetypes')
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: [
                    'All',
                    'Builder',
                    'Connector',
                    'Explorer',
                    'Strategist',
                    'Pioneer',
                    'Scholar',
                  ].length,
                  separatorBuilder: (context, index) =>
                      SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final archetype = [
                      'All',
                      'Builder',
                      'Connector',
                      'Explorer',
                      'Strategist',
                      'Pioneer',
                      'Scholar',
                    ][index];
                    final isSelected = archetype == state.selectedArchetype;
                    return ChoiceChip(
                      label: Text(archetype),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          HapticFeedback.selectionClick();
                          notifier.setArchetype(archetype);
                        }
                      },
                      selectedColor: context.colors.gold.withValues(alpha: 0.25),
                      backgroundColor: context.colors.card,
                      side: BorderSide(
                        color: isSelected ? context.colors.gold : context.colors.border,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? context.colors.textPrimary
                            : context.colors.textMuted,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: 12),

            // Main Content Area
            Expanded(
              child: state.selectedTab == 'Archetypes'
                  ? _buildMembersLeaderboard(context, state)
                  : _buildGuildsLeaderboard(context, state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersLeaderboard(
    BuildContext context,
    LeaderboardState state,
  ) {
    final members = state.filteredMembers;
    if (members.isEmpty) {
      return Center(
        child: Text(
          'No members found in this archetype category',
          style: TextStyle(color: context.colors.textMuted),
        ),
      );
    }

    final top3 = members.take(3).toList();
    final remaining = members.skip(3).toList();

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // 3D-styled Podium for Top 3
        if (top3.length >= 3) _buildPodium(context, top3),
        SizedBox(height: 20),

        Text(
          'SEASON RANKINGS',
          style: TextStyle(
            color: context.colors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        SizedBox(height: 10),

        // Leaderboard List
        ...remaining.map((entry) => _buildMemberTile(context, entry)),
        SizedBox(height: 40),
      ],
    );
  }

  Widget _buildPodium(BuildContext context, List<LeaderboardEntry> top3) {
    final first = top3[0];
    final second = top3[1];
    final third = top3[2];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 Silver
          _buildPodiumStep(
            context,
            entry: second,
            stepHeight: 90,
            badgeColor: Color(0xFFE2E8F0),
            rankNumber: '2',
          ),

          // #1 Gold (Taller)
          _buildPodiumStep(
            context,
            entry: first,
            stepHeight: 125,
            badgeColor: context.colors.gold,
            rankNumber: '1',
            hasCrown: true,
          ),

          // #3 Bronze
          _buildPodiumStep(
            context,
            entry: third,
            stepHeight: 75,
            badgeColor: Color(0xFFCD7F32),
            rankNumber: '3',
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep(
    BuildContext context, {
    required LeaderboardEntry entry,
    required double stepHeight,
    required Color badgeColor,
    required String rankNumber,
    bool hasCrown = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/profile/${entry.id}');
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: hasCrown ? 64 : 54,
                height: hasCrown ? 64 : 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: badgeColor,
                    width: hasCrown ? 3 : 2,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(entry.avatar),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (hasCrown)
                Positioned(
                  top: -8,
                  child: Icon(
                    Icons.workspace_premium,
                    color: context.colors.gold,
                    size: 24,
                  ),
                ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            entry.name.split(' ').first,
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${entry.xpThisWeek} XP',
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),

          // Platform Box
          Container(
            width: 80,
            height: stepHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  badgeColor.withValues(alpha: 0.3),
                  badgeColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
            ),
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 8),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#$rankNumber',
                style: TextStyle(
                  color: context.colors.background,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, LeaderboardEntry entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? context.colors.questBlue.withValues(alpha: 0.15)
            : context.colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: entry.isCurrentUser ? context.colors.questBlue : context.colors.border,
          width: entry.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/profile/${entry.id}');
        },
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.surface,
                border: Border.all(color: context.colors.border),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  color: context.colors.textPrimary70,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(entry.avatar),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.name,
                        style: TextStyle(
                          color: entry.isCurrentUser
                              ? context.colors.questBlue
                              : context.colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (entry.isCurrentUser) ...[
                        SizedBox(width: 6),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.questBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'YOU',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        QuestIcons.forArchetype(entry.archetype),
                        size: 12,
                        color: context.colors.textMuted,
                      ),
                      SizedBox(width: 4),
                      Text(
                        entry.archetype,
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.local_fire_department,
                        size: 12,
                        color: context.colors.gold,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${entry.streakDays}d streak',
                        style: TextStyle(
                          color: context.colors.gold,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.xpThisWeek} XP',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'this week',
                  style: TextStyle(color: context.colors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuildsLeaderboard(BuildContext context, LeaderboardState state) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.guilds.length,
      itemBuilder: (context, index) {
        final guild = state.guilds[index];
        final rankColors = [
          context.colors.gold,
          Color(0xFFE2E8F0),
          Color(0xFFCD7F32),
        ];
        final color = index < 3 ? rankColors[index] : context.colors.border;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.colors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: 0.6),
              width: index < 3 ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  image: DecorationImage(
                    image: NetworkImage(guild.bannerUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      context.colors.background.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  ),
                ),
                padding: EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${guild.rank}',
                        style: TextStyle(
                          color: context.colors.background,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.background54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        guild.category,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            guild.name,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${guild.membersCount} Active Members',
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${guild.weeklyXp} XP',
                          style: TextStyle(
                            color: context.colors.gold,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Weekly Score',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
