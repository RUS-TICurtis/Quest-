import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_provider.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return MockUserRepository();
});

abstract class UserRepository {
  Future<UserState> getUser(String userId);
  Future<void> updateUser(UserState user);
}

class MockUserRepository implements UserRepository {
  UserState _mockUser = const UserState(
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

  @override
  Future<UserState> getUser(String userId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockUser;
  }

  @override
  Future<void> updateUser(UserState user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    _mockUser = user;
  }
}
