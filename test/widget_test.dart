import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/app.dart';
import 'package:quest/features/communities/data/communities_provider.dart';
import 'package:quest/features/events/data/events_provider.dart';
import 'package:quest/features/home/data/stories_provider.dart';
import 'package:quest/features/messaging/data/chat_provider.dart';
import 'package:quest/features/profile/data/user_provider.dart';
import 'package:quest/features/stage/data/stage_provider.dart';
import 'package:quest/features/radar/data/radar_provider.dart';
import 'package:quest/features/leaderboard/data/leaderboard_provider.dart';

void main() {
  group('Quest Core Riverpod State Tests', () {
    test('UserNotifier handles XP gains and leveling up correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialUser = await container.read(userProvider.future);
      expect(initialUser.level, equals(4));
      expect(initialUser.currentXp, equals(840));

      // Add XP within current level
      await container.read(userProvider.notifier).addXp(100);
      expect((await container.read(userProvider.future)).currentXp, equals(940));
      expect((await container.read(userProvider.future)).level, equals(4));

      // Complete the pending daily quest (q2, 30 XP)
      final pendingQuest = (await container.read(userProvider.future)).dailyQuests.firstWhere((q) => !q.isDone);
      expect(pendingQuest.isCompleted, isFalse);

      await container.read(userProvider.notifier).toggleQuest(pendingQuest.id);
      final updatedQuest = (await container.read(userProvider.future)).dailyQuests.firstWhere((q) => q.id == pendingQuest.id);
      expect(updatedQuest.isCompleted, isTrue);
      // XP gained from completing the 30 XP quest: 940 + 30 = 970
      expect((await container.read(userProvider.future)).currentXp, equals(970));
    });

    test('EventsNotifier handles filtering, RSVPs and adding events', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialEvents = (await container.read(eventsProvider.future)).events;
      expect(initialEvents.isNotEmpty, isTrue);

      final eventToRsvp = initialEvents.first;
      final initialRsvpd = eventToRsvp.isRsvpd;
      final initialAttendees = eventToRsvp.attendeesCount;

      await container.read(eventsProvider.notifier).toggleRsvp(eventToRsvp.id);
      final updatedEvent = (await container.read(eventsProvider.future)).events.firstWhere((e) => e.id == eventToRsvp.id);
      expect(updatedEvent.isRsvpd, equals(!initialRsvpd));
      expect(updatedEvent.attendeesCount, equals(initialRsvpd ? initialAttendees - 1 : initialAttendees + 1));

      // Filter by category
      container.read(eventsProvider.notifier).setFilter('Tech');
      expect((await container.read(eventsProvider.future)).selectedFilter, equals('Tech'));

      // Add a new event
      const newEvent = Event(
        id: 'test_event_99',
        title: 'Flutter Hackathon 2026',
        description: 'Building innovative mobile experiences',
        location: 'Innovation Center',
        time: 'Tomorrow @ 5:00 PM',
        date: 'Tomorrow',
        category: 'Technology',
        communityId: '1',
        xpReward: 300,
        imageUrl: 'https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800',
        attendeesCount: 1,
        isRsvpd: true,
      );

      await container.read(eventsProvider.notifier).addEvent(newEvent);
      expect((await container.read(eventsProvider.future)).events.any((e) => e.id == 'test_event_99'), isTrue);
    });

    test('CommunitiesNotifier handles search, categories, and creation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(communitiesProvider.notifier).setCategory('Technology');
      expect(container.read(communitiesProvider).selectedCategory, equals('Technology'));

      container.read(communitiesProvider.notifier).setSearchQuery('Flutter');
      final filtered = container.read(communitiesProvider).filteredCommunities;
      expect(filtered.every((c) => c.name.toLowerCase().contains('flutter') || c.description.toLowerCase().contains('flutter')), isTrue);

      // Add community
      const newCommunity = Community(
        id: 'comm_99',
        name: 'AI Researchers Guild',
        description: 'Exploring machine learning and neural architectures',
        category: 'Technology',
        memberCount: 42,
      );
      container.read(communitiesProvider.notifier).addCommunity(newCommunity);
      expect(container.read(communitiesProvider).communities.any((c) => c.id == 'comm_99'), isTrue);
    });

    test('ChatNotifier handles sending messages and voice notes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialThreads = container.read(chatProvider).threads;
      expect(initialThreads.isNotEmpty, isTrue);

      final targetThreadId = initialThreads.first.id;
      final initialMessageCount = initialThreads.first.messages.length;

      container.read(chatProvider.notifier).sendMessage(
            threadId: targetThreadId,
            text: 'Hello from test suite!',
          );

      final updatedThread = container.read(chatProvider).getThreadById(targetThreadId);
      expect(updatedThread, isNotNull);
      expect(updatedThread!.messages.length, equals(initialMessageCount + 1));
      expect(updatedThread.messages.last.text, equals('Hello from test suite!'));

      // Send voice note
      container.read(chatProvider.notifier).sendVoiceNote(targetThreadId);
      final threadWithVoice = container.read(chatProvider).getThreadById(targetThreadId);
      expect(threadWithVoice!.messages.last.type, equals(MessageType.voiceNote));
    });

    test('StoriesNotifier adds and retrieves story highlights', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container.read(storiesProvider).length;
      const newStory = StoryItem(
        id: 'story_99',
        authorName: 'Curtis',
        authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
        timeAgo: 'Just now',
        title: 'New Guild Unlocked',
        content: 'We just crossed 500 members!',
      );

      container.read(storiesProvider.notifier).addStory(newStory);
      expect(container.read(storiesProvider).length, equals(initialCount + 1));
      expect(container.read(storiesProvider).first.id, equals('story_99'));
    });

    test('StageNotifier handles mic toggles, hand raises, and reactions', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialStage = container.read(stageProvider);
      expect(initialStage.isMicMuted, isTrue);
      expect(initialStage.isHandRaised, isFalse);

      container.read(stageProvider.notifier).toggleMic();
      expect(container.read(stageProvider).isMicMuted, isFalse);

      container.read(stageProvider.notifier).toggleHandRaise();
      expect(container.read(stageProvider).isHandRaised, isTrue);

      container.read(stageProvider.notifier).sendReaction('ðŸ”¥');
      expect(container.read(stageProvider).activeReactions.isNotEmpty, isTrue);
    });

    test('RadarNotifier handles hub selection and verified venue check-in', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialRadar = container.read(radarProvider);
      expect(initialRadar.hubs.isNotEmpty, isTrue);
      expect(initialRadar.checkedInHubId, isNull);

      container.read(radarProvider.notifier).selectHub('hub_2');
      expect(container.read(radarProvider).selectedHubId, equals('hub_2'));

      final didCheckIn = container.read(radarProvider.notifier).checkInToHub('hub_2');
      expect(didCheckIn, isTrue);
      expect(container.read(radarProvider).checkedInHubId, equals('hub_2'));

      // Check out
      final checkedOut = container.read(radarProvider.notifier).checkInToHub('hub_2');
      expect(checkedOut, isFalse);
      expect(container.read(radarProvider).checkedInHubId, isNull);
    });

    test('LeaderboardNotifier handles tabs and archetype filters', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialLeaderboard = container.read(leaderboardProvider);
      expect(initialLeaderboard.members.isNotEmpty, isTrue);
      expect(initialLeaderboard.guilds.isNotEmpty, isTrue);

      container.read(leaderboardProvider.notifier).setTab('Guild Leagues');
      expect(container.read(leaderboardProvider).selectedTab, equals('Guild Leagues'));

      container.read(leaderboardProvider.notifier).setArchetype('Builder');
      expect(container.read(leaderboardProvider).selectedArchetype, equals('Builder'));
      expect(container.read(leaderboardProvider).filteredMembers.every((m) => m.archetype == 'Builder'), isTrue);
    });
  });

  group('QuestApp Widget Smoke Tests', () {
    testWidgets('QuestApp boots and renders top-level widget hierarchy', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: QuestApp()));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byType(QuestApp), findsOneWidget);
    });
  });
}

