import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quest/core/theme/app_colors.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, name, username, "avatarUrl"')
          .or('name.ilike.%${query.trim()}%,username.ilike.%${query.trim()}%')
          .limit(20);

      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching users: $e'),
            backgroundColor: AppColors.crimson,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search for users...',
            hintStyle: TextStyle(color: AppColors.textSecondary),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear, color: AppColors.textSecondary),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
          ),
          onChanged: (value) {
            // Simple debounce can be implemented here if needed
            _performSearch(value);
          },
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.questBlue),
            )
          : _searchResults.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Type a name or username to search'
                        : 'No users found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.border,
                        backgroundImage: user['avatarUrl'] != null
                            ? NetworkImage(user['avatarUrl'])
                            : null,
                        child: user['avatarUrl'] == null
                            ? Icon(Icons.person, color: AppColors.textSecondary)
                            : null,
                      ),
                      title: Text(
                        user['name'] ?? '',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                      ),
                      subtitle: user['username'] != null
                          ? Text(
                              '@${user['username']}',
                              style: TextStyle(color: AppColors.textSecondary),
                            )
                          : null,
                      onTap: () {
                        context.push('/profile/${user['id']}');
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.chat_bubble_outline, color: AppColors.questBlue),
                        onPressed: () {
                          // TODO: Ensure chat room exists and route to it
                          // For now, route to a placeholder thread ID which should be generated
                          // in the real implementation based on roomId
                          context.push('/connect/${user['id']}'); 
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
