import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'leaderboard_repository.dart';

class LeaderboardEntry {
  final int rank;
  final String id;
  final String name;
  final String initials;
  final String avatar;
  final String archetype;
  final int xpThisWeek;
  final int streakDays;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.id,
    required this.name,
    required this.initials,
    required this.avatar,
    required this.archetype,
    required this.xpThisWeek,
    required this.streakDays,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      id: json['id'] as String,
      name: json['name'] as String,
      initials: json['initials'] as String,
      avatar: json['avatar'] as String,
      archetype: json['archetype'] as String,
      xpThisWeek: json['xpThisWeek'] as int,
      streakDays: json['streakDays'] as int,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'id': id,
      'name': name,
      'initials': initials,
      'avatar': avatar,
      'archetype': archetype,
      'xpThisWeek': xpThisWeek,
      'streakDays': streakDays,
      'isCurrentUser': isCurrentUser,
    };
  }
}

class GuildRanking {
  final int rank;
  final String id;
  final String name;
  final String category;
  final int membersCount;
  final int weeklyXp;
  final String bannerUrl;

  GuildRanking({
    required this.rank,
    required this.id,
    required this.name,
    required this.category,
    required this.membersCount,
    required this.weeklyXp,
    required this.bannerUrl,
  });

  factory GuildRanking.fromJson(Map<String, dynamic> json) {
    return GuildRanking(
      rank: json['rank'] as int,
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      membersCount: json['membersCount'] as int,
      weeklyXp: json['weeklyXp'] as int,
      bannerUrl: json['bannerUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'id': id,
      'name': name,
      'category': category,
      'membersCount': membersCount,
      'weeklyXp': weeklyXp,
      'bannerUrl': bannerUrl,
    };
  }
}

class LeaderboardState {
  final String selectedTab; // 'Archetypes', 'Global', 'Guilds'
  final String selectedArchetype;
  final List<LeaderboardEntry> members;
  final List<GuildRanking> guilds;

  LeaderboardState({
    this.selectedTab = 'Archetypes',
    this.selectedArchetype = 'All',
    required this.members,
    required this.guilds,
  });

  List<LeaderboardEntry> get filteredMembers {
    if (selectedArchetype == 'All') return members;
    return members
        .where(
          (m) => m.archetype.toLowerCase() == selectedArchetype.toLowerCase(),
        )
        .toList();
  }

  LeaderboardState copyWith({
    String? selectedTab,
    String? selectedArchetype,
    List<LeaderboardEntry>? members,
    List<GuildRanking>? guilds,
  }) {
    return LeaderboardState(
      selectedTab: selectedTab ?? this.selectedTab,
      selectedArchetype: selectedArchetype ?? this.selectedArchetype,
      members: members ?? this.members,
      guilds: guilds ?? this.guilds,
    );
  }
}

class LeaderboardNotifier extends AsyncNotifier<LeaderboardState> {
  late final LeaderboardRepository _repository;

  @override
  Future<LeaderboardState> build() async {
    _repository = ref.watch(leaderboardRepositoryProvider);

    final members = await _repository.getMembers();
    final guilds = await _repository.getGuilds();

    return LeaderboardState(members: members, guilds: guilds);
  }

  void setTab(String tab) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(selectedTab: tab));
    }
  }

  void setArchetype(String archetype) {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(selectedArchetype: archetype));
    }
  }
}

final leaderboardProvider =
    AsyncNotifierProvider<LeaderboardNotifier, LeaderboardState>(() {
      return LeaderboardNotifier();
    });
