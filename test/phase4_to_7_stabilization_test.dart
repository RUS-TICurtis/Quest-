import 'package:flutter_test/flutter_test.dart';
import 'package:quest/features/interaction/explore/data/global_search_repository.dart';
import 'package:quest/features/world/radar/data/radar_provider.dart';
import 'package:quest/features/society/communities/data/communities_provider.dart';
import 'package:quest/features/society/events/data/events_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/shared/models/creator_video.dart';

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

  group('Model Serialization Robustness', () {
    test('Community.fromJson safely handles null fields and snake_case', () {
      final json = {
        'id': 'comm_999',
        'name': 'Decentralized AI',
        'description': null,
        'category': null,
        'member_count': 42,
        'accent_color': 0xFF123456,
        'banner_url': 'https://example.com/banner.png',
      };

      final community = Community.fromJson(json);
      expect(community.id, 'comm_999');
      expect(community.name, 'Decentralized AI');
      expect(community.description, '');
      expect(community.category, 'General');
      expect(community.memberCount, 42);
      expect(community.bannerUrl, 'https://example.com/banner.png');
    });

    test('Event.fromJson safely handles null fields and snake_case', () {
      final json = {
        'id': 'ev_123',
        'community_id': 'comm_999',
        'title': 'Hackathon Opening',
        'date': null,
        'time': null,
        'location': null,
        'attendees_count': 150,
        'xp_reward': 300,
        'is_rsvpd': true,
      };

      final event = Event.fromJson(json);
      expect(event.id, 'ev_123');
      expect(event.communityId, 'comm_999');
      expect(event.title, 'Hackathon Opening');
      expect(event.date, 'Upcoming');
      expect(event.attendeesCount, 150);
      expect(event.xpReward, 300);
      expect(event.isRsvpd, isTrue);
    });

    test('UserState.fromJson safely parses snake_case and num values', () {
      final json = {
        'name': 'Alex Rivera',
        'username': 'arivera',
        'current_xp': 350.0,
        'level': 3.0,
        'xp_to_next_level': 500.0,
        'onboarding_completed': true,
      };

      final user = UserState.fromJson(json);
      expect(user.name, 'Alex Rivera');
      expect(user.currentXp, 350);
      expect(user.level, 3);
      expect(user.xpToNextLevel, 500);
      expect(user.onboardingCompleted, isTrue);
    });

    test('CreatorVideo.fromJson safely parses num counts and nested profile', () {
      final json = {
        'id': 'vid_456',
        'user_id': 'u_789',
        'video_url': 'https://example.com/video.mp4',
        'view_count': 1000.0,
        'like_count': 85.0,
        'duration_seconds': 45.0,
        'profiles': {
          'username': 'creator_pro',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
      };

      final video = CreatorVideo.fromJson(json);
      expect(video.id, 'vid_456');
      expect(video.creatorId, 'u_789');
      expect(video.viewCount, 1000);
      expect(video.likeCount, 85);
      expect(video.durationSeconds, 45);
      expect(video.creatorUsername, 'creator_pro');
      expect(video.creatorAvatarUrl, 'https://example.com/avatar.jpg');
    });
  });
}
