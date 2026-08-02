import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuestItem {
  final String id;
  final String title;
  final int xp;
  final bool isDone;

  bool get isCompleted => isDone;

  const QuestItem({
    required this.id,
    required this.title,
    required this.xp,
    this.isDone = false,
  });

  QuestItem copyWith({
    String? id,
    String? title,
    int? xp,
    bool? isDone,
  }) {
    return QuestItem(
      id: id ?? this.id,
      title: title ?? this.title,
      xp: xp ?? this.xp,
      isDone: isDone ?? this.isDone,
    );
  }
}

class UserState {
  final String name;
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

  const UserState({
    required this.name,
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
  });

  UserState copyWith({
    String? name,
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
  }) {
    return UserState(
      name: name ?? this.name,
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
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    return const UserState(
      name: 'Alex L.',
      initials: 'AL',
      level: 4,
      currentXp: 840,
      xpToNextLevel: 1000,
      streak: 12,
      archetypes: ['Creator', 'Connector'],
      badges: ['Early Adopter', '7-Day Streak', 'First Connection'],
      dailyQuests: [
        QuestItem(
          id: 'q1',
          title: 'RSVP to an event in your area',
          xp: 50,
          isDone: true,
        ),
        QuestItem(
          id: 'q2',
          title: 'Introduce yourself in a community chat',
          xp: 30,
          isDone: false,
        ),
        QuestItem(
          id: 'q3',
          title: 'Complete your profile bio & archetypes',
          xp: 20,
          isDone: true,
        ),
      ],
      joinedCommunityIds: ['1', '2', '6'],
      rsvpdEventIds: ['1'],
      recentlyLeveledUp: false,
    );
  }

  void addXp(int amount) {
    int newXp = state.currentXp + amount;
    int currentLevel = state.level;
    int needed = state.xpToNextLevel;
    bool leveledUp = false;

    while (newXp >= needed) {
      newXp -= needed;
      currentLevel++;
      needed = (needed * 1.25).toInt();
      leveledUp = true;
    }

    state = state.copyWith(
      currentXp: newXp,
      level: currentLevel,
      xpToNextLevel: needed,
      recentlyLeveledUp: leveledUp,
    );
  }

  void toggleQuest(String questId) {
    final updatedQuests = state.dailyQuests.map((q) {
      if (q.id == questId) {
        final newDone = !q.isDone;
        if (newDone) {
          addXp(q.xp);
        } else {
          // decrement if toggled off
          final decrementedXp = (state.currentXp - q.xp).clamp(0, state.xpToNextLevel);
          state = state.copyWith(currentXp: decrementedXp);
        }
        return q.copyWith(isDone: newDone);
      }
      return q;
    }).toList();

    state = state.copyWith(dailyQuests: updatedQuests);
  }

  void toggleJoinCommunity(String communityId) {
    final list = List<String>.from(state.joinedCommunityIds);
    if (list.contains(communityId)) {
      list.remove(communityId);
      state = state.copyWith(joinedCommunityIds: list);
    } else {
      list.add(communityId);
      state = state.copyWith(joinedCommunityIds: list);
      addXp(25);
    }
  }

  void toggleRsvpEvent(String eventId) {
    final list = List<String>.from(state.rsvpdEventIds);
    if (list.contains(eventId)) {
      list.remove(eventId);
      state = state.copyWith(rsvpdEventIds: list);
    } else {
      list.add(eventId);
      state = state.copyWith(rsvpdEventIds: list);
      addXp(30);
    }
  }

  void dismissLevelUp() {
    state = state.copyWith(recentlyLeveledUp: false);
  }

  void updateName(String newName) {
    final split = newName.trim().split(' ');
    String inits = 'Q';
    if (split.isNotEmpty && split.first.isNotEmpty) {
      inits = split.first[0].toUpperCase();
      if (split.length > 1 && split.last.isNotEmpty) {
        inits += split.last[0].toUpperCase();
      }
    }
    state = state.copyWith(name: newName, initials: inits);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});
