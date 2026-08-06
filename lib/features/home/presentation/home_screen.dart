import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/data/events_provider.dart';
import '../../profile/data/user_provider.dart';
import 'widgets/level_up_dialog.dart';
import 'widgets/stories_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final userState = (ref.watch(userProvider).value ?? UserState.initial());
    final eventsState = (ref.watch(eventsProvider).value ?? EventsState.initial());

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

    final progress = (userState.currentXp / userState.xpToNextLevel).clamp(0.0, 1.0);
    final upcomingEvents = eventsState.events.take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.questBlue,
        onPressed: () => _showQuickActionSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/profile'),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.questBlue,
                        child: Text(
                          userState.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, ${userState.name.split(' ').first}.',
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Ready to continue your journey?',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${userState.streak}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Stories Bar (Highlights)
              const StoriesBar(),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // XP Bar card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
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
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${userState.currentXp} / ${userState.xpToNextLevel} XP',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: AppColors.surface,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // AI Coach Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.skyBlue.withValues(alpha: 0.12),
                            AppColors.auroraPurple.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.skyBlue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: AppColors.skyBlue, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'AI COACH SUGGESTION',
                                    style: TextStyle(
                                      color: AppColors.skyBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => context.push('/messages/ai_coach'),
                                child: const Text(
                                  'Ask Guide →',
                                  style: TextStyle(
                                    color: AppColors.skyBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Three people nearby share your interests.',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'They are attending the Tech Startup Mixer tonight.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.skyBlue,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => context.push('/events/1'),
                            child: const Text(
                              'View Event',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Daily Quests
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daily Quests',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const Text(
                          'Resets in 8h',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...userState.dailyQuests.map((q) => _questTile(context, q)),

                    const SizedBox(height: 28),

                    // Upcoming Events
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upcoming Events',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/events'),
                          child: const Text(
                            'See all',
                            style: TextStyle(color: AppColors.questBlue, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (upcomingEvents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.event_busy, color: AppColors.textMuted, size: 40),
                            const SizedBox(height: 12),
                            const Text(
                              'No upcoming events',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Join more communities to see what\'s happening.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    else
                      ...upcomingEvents.map((e) => _eventTile(context, e)),

                    const SizedBox(height: 80),
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
            backgroundColor: AppColors.surface,
            duration: const Duration(seconds: 2),
            content: Row(
              children: [
                Icon(
                  quest.isDone ? Icons.undo : Icons.celebration,
                  color: quest.isDone ? AppColors.textMuted : AppColors.gold,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  quest.isDone ? 'Quest reset' : '+${quest.xp} XP Earned! Great job!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: quest.isDone ? AppColors.emerald.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              quest.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: quest.isDone ? AppColors.emerald : AppColors.border,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                quest.title,
                style: TextStyle(
                  color: quest.isDone ? AppColors.textMuted : Colors.white,
                  decoration: quest.isDone ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${quest.xp} XP',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _eventTile(BuildContext context, Event event) {
    return GestureDetector(
      onTap: () => context.push('/events/${event.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${event.attendeesCount} going',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${event.date}, ${event.time}',
              style: const TextStyle(
                color: AppColors.questBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              event.location,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.radar, color: AppColors.emerald),
                ),
                title: const Text('Participation Radar & Check-In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Scan nearby hubs and claim check-in XP', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/radar');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mic, color: AppColors.crimson),
                ),
                title: const Text('Join Live Stage Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Founder fireside & live audio discussion', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/stage/stage_1');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.leaderboard, color: AppColors.gold),
                ),
                title: const Text('Guild & Archetype Leaderboards', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Season 3 rankings & XP standings', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/leaderboard');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.questBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.event, color: AppColors.questBlue),
                ),
                title: const Text('Host an Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Publish a new workshop or meetup', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/organization');
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.skyBlue),
                ),
                title: const Text('Talk to Quest Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Ask for personalized recommendations', style: TextStyle(color: AppColors.textMuted)),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/messages/ai_coach');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


