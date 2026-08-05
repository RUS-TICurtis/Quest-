import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leaderboard_provider.dart';

abstract class LeaderboardRepository {
  Future<List<LeaderboardEntry>> getMembers();
  Future<List<GuildRanking>> getGuilds();
}

class MockLeaderboardRepository implements LeaderboardRepository {
  final List<LeaderboardEntry> _members = const [
    LeaderboardEntry(
      rank: 1,
      id: 'u1',
      name: 'Sarah Chen',
      initials: 'SC',
      avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
      archetype: 'Strategist',
      xpThisWeek: 3420,
      streakDays: 24,
    ),
    LeaderboardEntry(
      rank: 2,
      id: 'u2',
      name: 'Marcus Thorne',
      initials: 'MT',
      avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
      archetype: 'Builder',
      xpThisWeek: 3150,
      streakDays: 19,
    ),
    LeaderboardEntry(
      rank: 3,
      id: 'u3',
      name: 'Elena Rostova',
      initials: 'ER',
      avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
      archetype: 'Pioneer',
      xpThisWeek: 2890,
      streakDays: 15,
    ),
    LeaderboardEntry(
      rank: 4,
      id: 'u_curr',
      name: 'Alex L. (You)',
      initials: 'AL',
      avatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
      archetype: 'Connector',
      xpThisWeek: 2450,
      streakDays: 12,
      isCurrentUser: true,
    ),
    LeaderboardEntry(
      rank: 5,
      id: 'u4',
      name: 'David Kim',
      initials: 'DK',
      avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      archetype: 'Scholar',
      xpThisWeek: 2120,
      streakDays: 10,
    ),
    LeaderboardEntry(
      rank: 6,
      id: 'u5',
      name: 'Jessica Wu',
      initials: 'JW',
      avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
      archetype: 'Explorer',
      xpThisWeek: 1980,
      streakDays: 8,
    ),
  ];

  final List<GuildRanking> _guilds = const [
    GuildRanking(
      rank: 1,
      id: '1',
      name: 'Startup Founders',
      category: 'Entrepreneurship',
      membersCount: 1420,
      weeklyXp: 48600,
      bannerUrl: 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=800',
    ),
    GuildRanking(
      rank: 2,
      id: '2',
      name: 'SF Flutter Guild',
      category: 'Technology',
      membersCount: 890,
      weeklyXp: 41200,
      bannerUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800',
    ),
    GuildRanking(
      rank: 3,
      id: '3',
      name: 'AI Researchers & Builders',
      category: 'AI / ML',
      membersCount: 1150,
      weeklyXp: 38450,
      bannerUrl: 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800',
    ),
  ];

  @override
  Future<List<LeaderboardEntry>> getMembers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_members);
  }

  @override
  Future<List<GuildRanking>> getGuilds() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_guilds);
  }
}

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return MockLeaderboardRepository();
});
