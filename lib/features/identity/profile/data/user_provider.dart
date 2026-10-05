import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/data/user_repository.dart';
import 'package:quest/core/storage/local_storage_service.dart';

class QuestItem {
  final String id;
  final String title;
  final int xp;
  final bool isDone;
  final String category; // Personal, Social, Community, Event, Team, Exploration, Growth

  bool get isCompleted => isDone;

  QuestItem({
    required this.id,
    required this.title,
    required this.xp,
    this.isDone = false,
    this.category = 'Personal',
  });

  QuestItem copyWith({String? id, String? title, int? xp, bool? isDone, String? category}) {
    return QuestItem(
      id: id ?? this.id,
      title: title ?? this.title,
      xp: xp ?? this.xp,
      isDone: isDone ?? this.isDone,
      category: category ?? this.category,
    );
  }

  factory QuestItem.fromJson(Map<String, dynamic> json) {
    return QuestItem(
      id: json['id'] as String,
      title: json['title'] as String,
      xp: json['xp'] as int,
      isDone: json['isDone'] as bool? ?? false,
      category: json['category'] as String? ?? 'Personal',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'xp': xp, 'isDone': isDone, 'category': category};
  }
}

class UserState {
  final String name;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String initials;
  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final int streak;
  final List<String> archetypes;
  final List<String> badges;
  final List<QuestItem> dailyQuests;
  final List<String> joinedCommunityIds;
  final List<String> rsvpdEventIds;
  final bool recentlyLeveledUp;
  final String playStyle; // Explore, Participate, Compete, Grow, Create, Everything
  final bool onboardingCompleted;

  UserState({
    required this.name,
    this.username,
    this.avatarUrl,
    this.bio,
    required this.initials,
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.streak,
    required this.archetypes,
    required this.badges,
    required this.dailyQuests,
    required this.joinedCommunityIds,
    required this.rsvpdEventIds,
    this.recentlyLeveledUp = false,
    this.playStyle = 'Everything',
    this.onboardingCompleted = false,
  });

  factory UserState.initial() {
    return UserState(
      name: '',
      username: null,
      avatarUrl: null,
      bio: null,
      initials: '',
      level: 1,
      currentXp: 0,
      xpToNextLevel: 100,
      streak: 0,
      archetypes: [],
      badges: [],
      dailyQuests: [],
      joinedCommunityIds: [],
      rsvpdEventIds: [],
      playStyle: 'Everything',
      onboardingCompleted: false,
    );
  }

  UserState copyWith({
    String? name,
    String? username,
    String? avatarUrl,
    String? bio,
    String? initials,
    int? level,
    int? currentXp,
    int? xpToNextLevel,
    int? streak,
    List<String>? archetypes,
    List<String>? badges,
    List<QuestItem>? dailyQuests,
    List<String>? joinedCommunityIds,
    List<String>? rsvpdEventIds,
    bool? recentlyLeveledUp,
    String? playStyle,
    bool? onboardingCompleted,
  }) {
    return UserState(
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      initials: initials ?? this.initials,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      streak: streak ?? this.streak,
      archetypes: archetypes ?? this.archetypes,
      badges: badges ?? this.badges,
      dailyQuests: dailyQuests ?? this.dailyQuests,
      joinedCommunityIds: joinedCommunityIds ?? this.joinedCommunityIds,
      rsvpdEventIds: rsvpdEventIds ?? this.rsvpdEventIds,
      recentlyLeveledUp: recentlyLeveledUp ?? this.recentlyLeveledUp,
      playStyle: playStyle ?? this.playStyle,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  factory UserState.fromJson(Map<String, dynamic> json) {
    final rawAvatar = (json['avatarUrl'] ?? json['avatar_url']) as String?;
    final rawName = (json['name'] ?? json['full_name'] ?? 'Explorer')
        .toString();
    final rawInitials =
        json['initials'] as String? ??
        (rawName.isNotEmpty ? rawName[0].toUpperCase() : 'Q');

    return UserState(
      name: rawName,
      username: json['username'] as String?,
      avatarUrl: rawAvatar,
      bio: json['bio'] as String?,
      initials: rawInitials,
      level: json['level'] as int? ?? 1,
      currentXp: json['currentXp'] as int? ?? 0,
      xpToNextLevel: json['xpToNextLevel'] as int? ?? 100,
      streak: json['streak'] as int? ?? 0,
      archetypes:
          (json['archetypes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dailyQuests:
          (json['dailyQuests'] as List<dynamic>?)
              ?.map((e) => QuestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      joinedCommunityIds:
          (json['joinedCommunityIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      rsvpdEventIds:
          (json['rsvpdEventIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recentlyLeveledUp: json['recentlyLeveledUp'] as bool? ?? false,
      playStyle: json['playStyle'] as String? ?? 'Everything',
      onboardingCompleted: (json['onboardingCompleted'] ?? json['onboarding_completed']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'initials': initials,
      'level': level,
      'currentXp': currentXp,
      'xpToNextLevel': xpToNextLevel,
      'streak': streak,
      'archetypes': archetypes,
      'badges': badges,
      'dailyQuests': dailyQuests.map((e) => e.toJson()).toList(),
      'joinedCommunityIds': joinedCommunityIds,
      'rsvpdEventIds': rsvpdEventIds,
      'recentlyLeveledUp': recentlyLeveledUp,
      'playStyle': playStyle,
      'onboarding_completed': onboardingCompleted,
    };
  }
}

class UserNotifier extends AsyncNotifier<UserState> {
  late UserRepository _repository;

  @override
  Future<UserState> build() async {
    _repository = ref.watch(userRepositoryProvider);
    // Watch authProvider so the user profile re-fetches when authentication state changes
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id ?? '';

    // Guests have no persisted profile; give them a transient identity so the
    // UI never has to special-case a null profile. Nothing is written for them.
    if (authState.isGuest) {
      return UserState.initial().copyWith(
        name: 'Guest',
        initials: 'G',
        onboardingCompleted: true,
      );
    }

    final localStorage = ref.read(localStorageServiceProvider);
    try {
      // Backend is the source of truth.
      var fresh = await _repository.getUser(userId);
      if (userId.isNotEmpty && fresh.onboardingCompleted) {
        // TEMPORARY (backend dependency): the server does not persist XP/level
        // yet (needs an award_xp RPC), so locally earned progression is kept
        // when it is ahead of the server's. Everything else comes from server.
        final cachedProgress = localStorage.getProfile();
        if (cachedProgress != null) {
          final cLevel = cachedProgress['level'] as int;
          final cXp = cachedProgress['xp'] as int;
          if (cLevel > fresh.level ||
              (cLevel == fresh.level && cXp > fresh.currentXp)) {
            var needed = 100;
            for (var i = 1; i < cLevel; i++) {
              needed = (needed * 1.25).toInt();
            }
            fresh = fresh.copyWith(
              level: cLevel,
              currentXp: cXp,
              xpToNextLevel: needed,
            );
          }
        }
        await localStorage.saveProfile(
          name: fresh.name,
          avatarUrl: fresh.avatarUrl ?? '',
          xp: fresh.currentXp,
          level: fresh.level,
          username: fresh.username,
          bio: fresh.bio,
        );
      }
      return fresh;
    } catch (_) {
      // Offline/backend failure: fall back to the last known snapshot if one
      // exists, otherwise surface the error (AsyncError) instead of faking data.
      final cached = localStorage.getProfile();
      if (cached == null || userId.isEmpty) rethrow;
      final cachedName = cached['name'] as String;
      final cachedLevel = cached['level'] as int;
      var needed = 100;
      for (var i = 1; i < cachedLevel; i++) {
        needed = (needed * 1.25).toInt();
      }
      final cachedAvatar = cached['avatarUrl'] as String;
      return UserState.initial().copyWith(
        name: cachedName,
        initials: cachedName.isNotEmpty ? cachedName[0].toUpperCase() : 'Q',
        avatarUrl: cachedAvatar.isEmpty ? null : cachedAvatar,
        username: cached['username'] as String?,
        bio: cached['bio'] as String?,
        currentXp: cached['xp'] as int,
        level: cachedLevel,
        xpToNextLevel: needed,
        // The cache is only written after a successful server load.
        onboardingCompleted: true,
      );
    }
  }

  Future<void> _updateState(UserState newState) async {
    final previous = state.value;
    state = AsyncData(newState);

    try {
      await _repository.updateUser(newState);
    } catch (_) {
      // Roll back the optimistic update so the UI never claims a save the
      // backend rejected, then let the caller present the error.
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }

    final localStorage = ref.read(localStorageServiceProvider);
    await localStorage.saveProfile(
      name: newState.name,
      avatarUrl: newState.avatarUrl ?? '',
      xp: newState.currentXp,
      level: newState.level,
      username: newState.username,
      bio: newState.bio,
    );
  }

  Future<void> updateProfile(UserState newState) async {
    await _updateState(newState);
  }

  Future<void> addXp(int amount) async {
    final currentState = state.value;
    if (currentState == null) return;

    int newXp = currentState.currentXp + amount;
    int currentLevel = currentState.level;
    int needed = currentState.xpToNextLevel;
    bool leveledUp = false;

    while (newXp >= needed) {
      newXp -= needed;
      currentLevel++;
      needed = (needed * 1.25).toInt();
      leveledUp = true;
    }

    await _updateState(
      currentState.copyWith(
        currentXp: newXp,
        level: currentLevel,
        xpToNextLevel: needed,
        recentlyLeveledUp: leveledUp,
      ),
    );
  }

  Future<void> toggleQuest(String questId) async {
    final currentState = state.value;
    if (currentState == null) return;

    bool xpAdded = false;
    int xpAmount = 0;
    bool xpRemoved = false;

    final updatedQuests = currentState.dailyQuests.map((q) {
      if (q.id == questId) {
        final newDone = !q.isDone;
        if (newDone) {
          xpAdded = true;
          xpAmount = q.xp;
        } else {
          xpRemoved = true;
          xpAmount = q.xp;
        }
        return q.copyWith(isDone: newDone);
      }
      return q;
    }).toList();

    var nextState = currentState.copyWith(dailyQuests: updatedQuests);
    state = AsyncData(nextState);

    if (xpAdded) {
      await addXp(xpAmount);
    } else if (xpRemoved) {
      final decrementedXp = (nextState.currentXp - xpAmount).clamp(
        0,
        nextState.xpToNextLevel,
      );
      await _updateState(nextState.copyWith(currentXp: decrementedXp));
    } else {
      await _updateState(nextState);
    }
  }

  Future<void> toggleJoinCommunity(String communityId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final list = List<String>.from(currentState.joinedCommunityIds);
    if (list.contains(communityId)) {
      list.remove(communityId);
      await _updateState(currentState.copyWith(joinedCommunityIds: list));
    } else {
      list.add(communityId);
      state = AsyncData(currentState.copyWith(joinedCommunityIds: list));
      await addXp(25);
    }
  }

  Future<void> toggleRsvpEvent(String eventId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final list = List<String>.from(currentState.rsvpdEventIds);
    if (list.contains(eventId)) {
      list.remove(eventId);
      await _updateState(currentState.copyWith(rsvpdEventIds: list));
    } else {
      list.add(eventId);
      state = AsyncData(currentState.copyWith(rsvpdEventIds: list));
      await addXp(30);
    }
  }

  Future<void> dismissLevelUp() async {
    final currentState = state.value;
    if (currentState == null) return;
    await _updateState(currentState.copyWith(recentlyLeveledUp: false));
  }

  Future<void> updateName(String newName) async {
    final currentState = state.value;
    if (currentState == null) return;

    final split = newName.trim().split(' ');
    String inits = 'Q';
    if (split.isNotEmpty && split.first.isNotEmpty) {
      inits = split.first[0].toUpperCase();
      if (split.length > 1 && split.last.isNotEmpty) {
        inits += split.last[0].toUpperCase();
      }
    }
    await _updateState(currentState.copyWith(name: newName, initials: inits));
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});
