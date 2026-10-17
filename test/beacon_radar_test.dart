import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/world/radar/data/beacon_model.dart';

void main() {
  group('BeaconModel Unit Tests', () {
    test('instantiates and serializes BeaconModel correctly', () {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 2));

      final beacon = BeaconModel(
        id: 'b_123',
        creatorId: 'u_user1',
        creatorName: 'Alex Rivers',
        creatorAvatar: 'https://example.com/avatar.jpg',
        title: 'Spontaneous Bible Study & Coffee',
        description: 'Meeting at Main Cafe patio.',
        hubId: 'hub_innovation',
        hubName: 'Downtown Tech District',
        createdAt: now,
        expiresAt: expiresAt,
        attendeeIds: ['u_user1', 'u_user2'],
        attendeeAvatars: [
          'https://example.com/avatar.jpg',
          'https://example.com/avatar2.jpg',
        ],
        xpReward: 50,
        angleRatio: 0.42,
        radiusRatio: 0.65,
      );

      expect(beacon.id, equals('b_123'));
      expect(beacon.creatorId, equals('u_user1'));
      expect(beacon.title, equals('Spontaneous Bible Study & Coffee'));
      expect(beacon.attendeeCount, equals(2));
      expect(beacon.isUserJoined('u_user1'), isTrue);
      expect(beacon.isUserJoined('u_user2'), isTrue);
      expect(beacon.isUserJoined('u_unknown'), isFalse);
      expect(beacon.isExpired, isFalse);

      final json = beacon.toJson();
      expect(json['id'], equals('b_123'));
      expect(json['creator_id'], equals('u_user1'));
      expect(json['xp_reward'], equals(50));
      expect(json['attendee_ids'], contains('u_user2'));

      final fromJson = BeaconModel.fromJson(json);
      expect(fromJson.id, equals(beacon.id));
      expect(fromJson.creatorName, equals(beacon.creatorName));
      expect(fromJson.title, equals(beacon.title));
      expect(fromJson.attendeeIds.length, equals(2));
    });

    test('handles timeRemainingFormatted and expiration states', () {
      final now = DateTime.now();

      final activeBeacon = BeaconModel(
        id: 'b_active',
        creatorId: 'u_1',
        creatorName: 'Jordan',
        creatorAvatar: '',
        title: 'Active Meetup',
        description: '',
        hubId: 'hub_1',
        hubName: 'Hub',
        createdAt: now.subtract(const Duration(minutes: 30)),
        expiresAt: now.add(const Duration(minutes: 90)),
        angleRatio: 0.2,
        radiusRatio: 0.5,
      );

      expect(activeBeacon.isExpired, isFalse);
      expect(activeBeacon.timeRemainingFormatted, contains('1h'));

      final expiringSoonBeacon = BeaconModel(
        id: 'b_soon',
        creatorId: 'u_1',
        creatorName: 'Jordan',
        creatorAvatar: '',
        title: 'Ending Soon',
        description: '',
        hubId: 'hub_1',
        hubName: 'Hub',
        createdAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(const Duration(minutes: 25)),
        angleRatio: 0.2,
        radiusRatio: 0.5,
      );

      expect(expiringSoonBeacon.isExpired, isFalse);
      expect(expiringSoonBeacon.timeRemainingFormatted, endsWith('m left'));

      final expiredBeacon = BeaconModel(
        id: 'b_expired',
        creatorId: 'u_1',
        creatorName: 'Jordan',
        creatorAvatar: '',
        title: 'Expired Meetup',
        description: '',
        hubId: 'hub_1',
        hubName: 'Hub',
        createdAt: now.subtract(const Duration(hours: 3)),
        expiresAt: now.subtract(const Duration(minutes: 10)),
        angleRatio: 0.2,
        radiusRatio: 0.5,
      );

      expect(expiredBeacon.isExpired, isTrue);
      expect(expiredBeacon.timeRemainingFormatted, equals('Expiring now'));
    });

    test('copyWith properly updates attendees and properties', () {
      final now = DateTime.now();
      final beacon = BeaconModel(
        id: 'b_copy',
        creatorId: 'u_creator',
        creatorName: 'Creator',
        creatorAvatar: '',
        title: 'Original Title',
        description: 'Original Desc',
        hubId: 'hub_1',
        hubName: 'Hub',
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
        attendeeIds: ['u_creator'],
        attendeeAvatars: ['https://example.com/c.jpg'],
        angleRatio: 0.3,
        radiusRatio: 0.5,
      );

      final updated = beacon.copyWith(
        title: 'Updated Title',
        attendeeIds: ['u_creator', 'u_new_attendee'],
        attendeeAvatars: ['https://example.com/c.jpg', 'https://example.com/new.jpg'],
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.description, equals('Original Desc'));
      expect(updated.attendeeCount, equals(2));
      expect(updated.isUserJoined('u_new_attendee'), isTrue);
    });
  });
}
