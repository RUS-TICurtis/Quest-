import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/interaction/messaging/data/chat_provider.dart';

class UserDiscoveryScreen extends ConsumerStatefulWidget {
  const UserDiscoveryScreen({super.key});

  @override
  ConsumerState<UserDiscoveryScreen> createState() => _UserDiscoveryScreenState();
}

class _UserDiscoveryScreenState extends ConsumerState<UserDiscoveryScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final chatStateAsync = ref.watch(chatProvider);
    final chatState = chatStateAsync.value;

    if (chatState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Users would be queried from Supabase dynamically using Supabase.instance.client.from('profiles').select().
    // Here we use chat threads that simulate available users.
    final users = chatState.threads.where((t) => !t.isGroup && !t.isChannel && !t.isAiCoach).toList();

    final filteredUsers = users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.title.toLowerCase().contains(q) || (u.userHandle?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        backgroundColor: context.colors.background,
        elevation: 0,
        title: const Text('New Message', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: context.colors.questBlue,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: context.colors.textMuted, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredUsers.length,
              separatorBuilder: (_, __) => Divider(color: context.colors.border, height: 1, indent: 70),
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.colors.questBlue.withValues(alpha: 0.2),
                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.title.isNotEmpty ? user.title[0].toUpperCase() : 'U',
                            style: TextStyle(color: context.colors.questBlue),
                          )
                        : null,
                  ),
                  title: Text(
                    user.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    user.userHandle != null ? '@${user.userHandle}' : 'Available',
                    style: TextStyle(color: context.colors.textMuted),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/connect/${user.id}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
