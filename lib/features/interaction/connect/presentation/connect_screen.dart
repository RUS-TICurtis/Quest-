import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';
import 'package:quest/features/interaction/messaging/presentation/messages_screen.dart';
import 'package:quest/features/society/communities/presentation/communities_screen.dart';
import 'package:quest/features/society/events/presentation/events_screen.dart';
import 'package:quest/features/world/radar/presentation/radar_screen.dart';
import 'package:quest/features/interaction/home/presentation/widgets/stories_bar.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const ConnectScreen({super.key, this.initialTab});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<_ConnectTabItem> _tabs = const [
    _ConnectTabItem(title: 'Messages', icon: Icons.chat_bubble_outline_rounded),
    _ConnectTabItem(title: 'Communities', icon: Icons.groups_outlined),
    _ConnectTabItem(title: 'Events', icon: Icons.event_outlined),
    _ConnectTabItem(title: 'Radar', icon: Icons.radar_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = _resolveInitialIndex(widget.initialTab);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant ConnectScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab && widget.initialTab != null) {
      final newIndex = _resolveInitialIndex(widget.initialTab);
      if (newIndex != _tabController.index) {
        _tabController.animateTo(newIndex);
      }
    }
  }

  int _resolveInitialIndex(String? tabName) {
    switch (tabName?.toLowerCase()) {
      case 'communities':
        return 1;
      case 'events':
        return 2;
      case 'radar':
        return 3;
      case 'messages':
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider).value;
    final unreadMessages =
        chatState?.threads.fold<int>(0, (sum, t) => sum + t.unreadCount) ?? 0;

    return Scaffold(
      backgroundColor: context.colors.background,
      floatingActionButton: _tabController.index == 0
          ? Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'ai_coach',
                  backgroundColor: context.colors.questBlue,
                  elevation: 4,
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/connect/ai_coach');
                  },
                ),
                const SizedBox(height: 14),
                FloatingActionButton(
                  heroTag: 'new_message',
                  backgroundColor: context.colors.questBlue,
                  elevation: 4,
                  child: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    context.push('/connect/user_discovery');
                  },
                ),
              ],
            )
          : null,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: context.colors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const StoriesBar(),
            const SizedBox(height: 6),
            // Segmented Connect Hub Tabs
            Container(
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.colors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: context.colors.questBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: context.colors.textMuted,
                labelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                onTap: (_) => HapticFeedback.selectionClick(),
                tabs: List.generate(_tabs.length, (i) {
                  final tab = _tabs[i];
                  final hasUnread = i == 0 && unreadMessages > 0;
                  return Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tab.icon, size: 16),
                        const SizedBox(width: 5),
                        Text(tab.title),
                        if (hasUnread) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.crimson,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$unreadMessages',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            // Hub Content View
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // stable inner tabs
                children: const [
                  MessagesScreen(),
                  CommunitiesScreen(),
                  EventsScreen(),
                  RadarScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectTabItem {
  final String title;
  final IconData icon;
  const _ConnectTabItem({required this.title, required this.icon});
}
