import 'package:flutter/material.dart';
import 'package:quest/features/interaction/messaging/presentation/messages_screen.dart';
import 'package:quest/features/society/communities/presentation/communities_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

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
      appBar: AppBar(
        title: Text('Connect'),
        elevation: 0,
        bottom: TabBar(
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
      body: TabBarView(
        controller: _tabController,
        children: [MessagesScreen(), CommunitiesScreen()],
      ),
    );
  }
}
