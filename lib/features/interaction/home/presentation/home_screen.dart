import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/society/events/data/events_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'widgets/level_up_dialog.dart';
import 'widgets/stories_bar.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final userState = (ref.watch(userProvider).value ?? UserState.initial());
    final eventsState =
        (ref.watch(eventsProvider).value ?? EventsState.initial());

    // Trigger level up modal if user recently leveled up
    ref.listen<AsyncValue<UserState>>(userProvider, (previousAsync, nextAsync) {
      final next = nextAsync.value;
      if (next == null) return;
      if (next.recentlyLeveledUp) {
        LevelUpDialog.show(
          context,
          newLevel: next.level,
          onDismiss: () {
            ref.read(userProvider.notifier).dismissLevelUp();
          },
        );
      }
    });

    final progress = (userState.currentXp / userState.xpToNextLevel).clamp(
      0.0,
      1.0,
    );
    final upcomingEvents = eventsState.events.take(3).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: context.colors.questBlue,
        onPressed: () {
          HapticFeedback.lightImpact();
          _showQuickActionSheet(context);
        },
        child: Icon(Icons.add, color: context.colors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go('/profile');
                      },
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: context.colors.questBlue,
                        child: Text(
                          userState.initials,
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, ${userState.name.split(' ').first}.',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ready to continue your journey?',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            color: context.colors.amber,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${userState.streak}',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 18),

              // Stories Bar (Highlights)
              StoriesBar(),

              SizedBox(height: 16),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/feed');
                  },
                  icon: Icon(Icons.play_circle_fill, color: Colors.white),
                  label: Text(
                    'Watch Video Feed',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.questBlue,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    shadowColor: context.colors.questBlue.withValues(alpha: 0.5),
                  ),
                ),
              ),

              SizedBox(height: 16),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // XP Bar card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.colors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Lvl ${userState.level} ${userState.archetypes.join(" & ")}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.colors.gold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${userState.currentXp} / ${userState.xpToNextLevel} XP',
                                style: TextStyle(
                                  color: context.colors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: context.colors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                context.colors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // AI Coach Card
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.colors.skyBlue.withValues(alpha: 0.12),
                            context.colors.auroraPurple.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.colors.skyBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: context.colors.skyBlue,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI COACH SUGGESTION',
                                    style: TextStyle(
                                      color: context.colors.skyBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.push('/connect/ai_coach');
                                },
                                child: Text(
                                  'Ask Guide →',
                                  style: TextStyle(
                                    color: context.colors.skyBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Three people nearby share your interests.',
                            style: TextStyle(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'They are attending the Tech Startup Mixer tonight.',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.skyBlue,
                              foregroundColor: context.colors.background,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.push('/events/1');
                            },
                            child: Text(
                              'View Event',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 28),

                    // Daily Quests
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Quests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        Text(
                          'Resets in 8h',
                          style: TextStyle(
                            color: context.colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...userState.dailyQuests.map((q) => _questTile(context, q)),

                    SizedBox(height: 28),

                    // Upcoming Events
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Events',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            context.go('/events');
                          },
                          child: Text(
                            'See all',
                            style: TextStyle(
                              color: context.colors.questBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (upcomingEvents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: context.colors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              color: context.colors.textMuted,
                              size: 40,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No upcoming events',
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Join more communities to see what\'s happening.',
                              style: TextStyle(
                                color: context.colors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...upcomingEvents.map((e) => _eventTile(context, e)),

                    SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questTile(BuildContext context, QuestItem quest) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(userProvider.notifier).toggleQuest(quest.id);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: context.colors.surface,
            duration: Duration(seconds: 2),
            content: Row(
              children: [
                Icon(
                  quest.isDone ? Icons.undo : Icons.celebration,
                  color: quest.isDone ? context.colors.textMuted : context.colors.gold,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  quest.isDone
                      ? 'Quest reset'
                      : '+${quest.xp} XP Earned! Great job!',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: quest.isDone
                ? context.colors.emerald.withValues(alpha: 0.3)
                : context.colors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              quest.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: quest.isDone ? context.colors.emerald : context.colors.border,
              size: 24,
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                quest.title,
                style: TextStyle(
                  color: quest.isDone
                      ? context.colors.textMuted
                      : context.colors.textPrimary,
                  decoration: quest.isDone ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: context.colors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${quest.xp} XP',
                style: TextStyle(
                  color: context.colors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eventTile(BuildContext context, Event event) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/events/${event.id}');
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Text(
                    '${event.attendeesCount} going',
                    style: TextStyle(
                      color: context.colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              '${event.date}, ${event.time}',
              style: TextStyle(
                color: context.colors.questBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              event.location,
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.radar, color: context.colors.emerald),
                ),
                title: Text(
                  'Participation Radar & Check-In',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Scan nearby hubs and claim check-in XP',
                  style: TextStyle(color: context.colors.textMuted),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  context.push('/radar');
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.crimson.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.mic, color: context.colors.crimson),
                ),
                title: Text(
                  'Join Live Stage Room',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Founder fireside & live audio discussion',
                  style: TextStyle(color: context.colors.textMuted),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  context.push('/stage/stage_1');
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.leaderboard, color: context.colors.gold),
                ),
                title: Text(
                  'Guild & Archetype Leaderboards',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Season 3 rankings & XP standings',
                  style: TextStyle(color: context.colors.textMuted),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  context.push('/leaderboard');
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.questBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.event, color: context.colors.questBlue),
                ),
                title: Text(
                  'Host an Event',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Publish a new workshop or meetup',
                  style: TextStyle(color: context.colors.textMuted),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  context.push('/organization');
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.colors.skyBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: context.colors.skyBlue,
                  ),
                ),
                title: Text(
                  'Talk to Quest Guide',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Ask for personalized recommendations',
                  style: TextStyle(color: context.colors.textMuted),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  context.push('/connect/ai_coach');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
