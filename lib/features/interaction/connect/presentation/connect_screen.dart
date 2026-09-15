import 'package:flutter/material.dart';
import 'package:quest/features/interaction/messaging/presentation/messages_screen.dart';
import 'package:quest/features/society/communities/presentation/communities_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class ConnectScreen extends ConsumerStatefulWidget {
  const ConnectScreen({super.key});

  @override
  ConsumerState<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends ConsumerState<ConnectScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: 16),
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
      body: Column(
        children: [
          Container(
            color: context.colors.background,
            child: TabBar(
              controller: _tabController,
              indicatorColor: context.colors.questBlue,
              labelColor: context.colors.questBlue,
              unselectedLabelColor: context.colors.textMuted,
              dividerColor: context.colors.border,
              tabs: [
                Tab(text: 'Chats'),
                Tab(text: 'Communities'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [MessagesScreen(), CommunitiesScreen()],
            ),
          ),
        ],
      ),
    );
  }
}
