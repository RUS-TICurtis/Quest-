import 'package:flutter/material.dart';
import 'package:quest/features/interaction/messaging/presentation/messages_screen.dart';
import 'package:quest/features/interaction/home/presentation/widgets/stories_bar.dart';

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
  final List<String> _categories = [
    'All',
    'Direct',
    'Groups',
    'Channels',
    'Bots',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: context.colors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const StoriesBar(),
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = _tabController.index == i;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _tabController.animateTo(i);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? context.colors.questBlue
                          : context.colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? context.colors.questBlue
                            : context.colors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _categories[i],
                        style: TextStyle(
                          color: isSelected ? Colors.white : context.colors.textMuted,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                MessagesScreen(categoryIndex: 0),
                MessagesScreen(categoryIndex: 1),
                MessagesScreen(categoryIndex: 2),
                MessagesScreen(categoryIndex: 3),
                MessagesScreen(categoryIndex: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
