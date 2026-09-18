import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/storage/local_database_service.dart';
import 'package:quest/core/storage/models/cached_member_profile.dart';
import 'package:quest/core/theme/quest_icons.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemberProfileScreen extends ConsumerStatefulWidget {
  final String memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  ConsumerState<MemberProfileScreen> createState() =>
      _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  bool _hasEndorsed = false;
  UserState _memberProfile = UserState.initial();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final localDb = ref.read(localDatabaseProvider);

    // 1. Instant cache hit from Hive (no network wait)
    final cached = localDb.getCachedProfile(widget.memberId);
    if (cached != null && mounted) {
      setState(() {
        _memberProfile = _fromCached(cached);
        _isLoading = false;
      });
      // If cache is fresh (< 15 min), skip network fetch
      if (!cached.isStale) return;
    }

    // 2. Background network refresh from Supabase
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', widget.memberId)
          .maybeSingle();

      if (data != null && mounted) {
        final freshProfile = UserState.fromJson(data);
        // Update Isar cache with fresh data
        await localDb.cacheProfile(
          CachedMemberProfile.fromSupabaseJson(data),
        );
        if (mounted) {
          setState(() {
            _memberProfile = freshProfile;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  UserState _fromCached(CachedMemberProfile cached) {
    return UserState.initial().copyWith(
      name: cached.name,
      username: cached.username,
      avatarUrl: cached.avatarUrl,
      bio: cached.bio,
      initials: cached.initials ?? (cached.name.isNotEmpty
          ? cached.name[0].toUpperCase()
          : 'Q'),
      level: cached.level,
      currentXp: cached.currentXp,
      xpToNextLevel: cached.xpToNextLevel,
      streak: cached.streak,
      archetypes: cached.archetypes,
      badges: cached.badges,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _memberProfile.name.isEmpty) {
      return Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: context.colors.questBlue,
          ),
        ),
      );
    }

    final name = _memberProfile.name.isEmpty ? 'Explorer' : _memberProfile.name;
    final initials = _memberProfile.initials.isEmpty
        ? (name.isNotEmpty ? name[0].toUpperCase() : 'Q')
        : _memberProfile.initials;
    final bio = _memberProfile.bio ?? '';
    final level = _memberProfile.level;
    final currentXp = _memberProfile.currentXp;
    final streak = _memberProfile.streak;
    final archetypes = _memberProfile.archetypes;
    final badges = _memberProfile.badges;
    final username = _memberProfile.username;
    final subtitle = (username != null && username.isNotEmpty)
        ? '@$username'
        : (archetypes.isNotEmpty ? archetypes.join(' • ') : 'Member');

    // Placeholder archetype score map derived from archetypes list
    final archetypeScores = <String, int>{
      for (final a in archetypes)
        a: 50 + archetypes.indexOf(a) * 10,
    };
    // Ensure Strategist + other common ones are always shown
    const allArchetypes = [
      'Strategist', 'Builder', 'Pioneer',
      'Connector', 'Explorer', 'Scholar'
    ];
    for (final a in allArchetypes) {
      archetypeScores.putIfAbsent(a, () => 0);
    }

    return Scaffold(
      backgroundColor: context.colors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar with Gradient Banner
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            elevation: 0,
            backgroundColor: context.colors.background,
            title: Text(
              name,
              style: TextStyle(color: context.colors.textPrimary),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              },
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar & Action Row
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.surface,
                            border: Border.all(
                              color: context.colors.background,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.background.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.questBlue,
                            foregroundColor: context.colors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          icon: Icon(Icons.chat_bubble_outline, size: 16),
                          label: Text(
                            'Message',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            context.push('/messages/t1');
                          },
                        ),
                        SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _hasEndorsed
                                ? context.colors.gold
                                : context.colors.textPrimary,
                            side: BorderSide(
                              color: _hasEndorsed
                                  ? context.colors.gold
                                  : context.colors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                          child: Icon(
                            _hasEndorsed ? Icons.star : Icons.star_border,
                            size: 18,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            if (!_hasEndorsed) {
                              setState(() {
                                _hasEndorsed = true;
                              });
                              ref.read(userProvider.notifier).addXp(25);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: context.colors.card,
                                  content: Row(
                                    children: [
                                      Icon(
                                        Icons.workspace_premium,
                                        color: context.colors.gold,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Endorsed archetype! +25 XP awarded.',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Name, Bio & Level
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.gold.withValues(
                                  alpha: 0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.colors.gold.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              child: Text(
                                'LVL $level',
                                style: TextStyle(
                                  color: context.colors.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: archetypes.map((arch) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.colors.questBlue.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    QuestIcons.forArchetype(arch),
                                    size: 12,
                                    color: context.colors.questBlue,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    arch,
                                    style: TextStyle(
                                      color: context.colors.textPrimary70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 10),
                        Text(
                          bio,
                          style: TextStyle(
                            color: context.colors.textPrimary70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 16),

                        // Stats Summary Row
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Total XP',
                                '$currentXp',
                                Icons.bolt,
                                context.colors.gold,
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: context.colors.border,
                              ),
                              _buildStatItem(
                                'Streak',
                                '$streak Days',
                                Icons.local_fire_department,
                                context.colors.crimson,
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: context.colors.border,
                              ),
                              _buildStatItem(
                                'Badges',
                                '${badges.length}',
                                Icons.military_tech,
                                context.colors.emerald,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),

                        // Archetype Radar Matrix Breakdown
                        Text(
                          'ARCHETYPE MATRIX SCORE',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 12),

                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: Column(
                            children: archetypeScores.entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      QuestIcons.forArchetype(entry.key),
                                      size: 14,
                                      color: context.colors.questBlue,
                                    ),
                                    SizedBox(width: 8),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        entry.key,
                                        style: TextStyle(
                                          color: context.colors.textPrimary70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                          value: entry.value / 100.0,
                                          backgroundColor:
                                              context.colors.surface,
                                          valueColor: AlwaysStoppedAnimation(
                                            entry.value > 80
                                                ? context.colors.gold
                                                : context.colors.questBlue,
                                          ),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      '${entry.value}%',
                                      style: TextStyle(
                                        color: context.colors.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Badges Grid
                        Text(
                          'UNLOCKED REPUTATION BADGES',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 12),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: badges.map((b) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: context.colors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.colors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    color: context.colors.gold,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    b,
                                    style: TextStyle(
                                      color: context.colors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: context.colors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}
