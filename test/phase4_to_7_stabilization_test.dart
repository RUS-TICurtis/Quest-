import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/interaction/explore/data/global_search_repository.dart';
import 'package:quest/features/world/radar/data/radar_provider.dart';

void main() {
  group('GlobalSearchResults Stabilization', () {
    test('GlobalSearchResults.empty() has zero items and isEmpty is true', () {
      const results = GlobalSearchResults.empty();
      expect(results.isEmpty, isTrue);
      expect(results.isNotEmpty, isFalse);
      expect(results.users, isEmpty);
      expect(results.quests, isEmpty);
      expect(results.events, isEmpty);
      expect(results.communities, isEmpty);
    });

    test('UserSearchResult parses trust score correctly', () {
      final json = {
        'id': 'test-uuid-1234',
        'name': 'Test Explorer',
        'username': 'explorer_test',
        'avatar_url': 'https://example.com/avatar.png',
        'bio': 'Testing Quest App',
        'archetypes': ['Adventurer', 'Builder'],
        'level': 5,
        'user_trust_scores': {'score': 85.0, 'level': 'Gold'},
      };

      final user = UserSearchResult.fromJson(json);
      expect(user.id, 'test-uuid-1234');
      expect(user.name, 'Test Explorer');
      expect(user.trustScore, 85.0);
      expect(user.trustLevel, 'Gold');
      expect(user.archetypes, contains('Adventurer'));
      expect(user.level, 5);
    });
  });

  group('Radar Data Integrity', () {
    test('HubLocation parses from json properly', () {
      final json = {
        'id': 'hub_1',
        'name': 'Test Tech Hub',
        'address': '123 Main St',
        'category': 'Tech',
        'activeMembersCount': 12,
        'distanceMiles': 0.5,
        'isVerified': true,
        'xpBonus': 100,
        'imageUrl': 'https://example.com/hub.jpg',
      };

      final hub = HubLocation.fromJson(json);
      expect(hub.id, 'hub_1');
      expect(hub.name, 'Test Tech Hub');
      expect(hub.activeMembersCount, 12);
      expect(hub.distanceMiles, 0.5);
    });

    test('RadarState handles empty nearby members without error', () {
      final state = RadarState(
        hubs: [
          HubLocation(
            id: 'hub_1',
            name: 'Hub 1',
            address: 'Address 1',
            category: 'Tech',
            activeMembersCount: 0,
            distanceMiles: 0.1,
            imageUrl: 'https://example.com/img.jpg',
          ),
        ],
        nearbyMembers: const [],
      );

      expect(state.nearbyMembers, isEmpty);
      expect(state.currentSelectedHub?.id, 'hub_1');
      expect(state.isUserCheckedIn('hub_1'), isFalse);
    });
  });
}
