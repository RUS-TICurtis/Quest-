with open("lib/features/interaction/connect/presentation/user_discovery_screen.dart", "r") as f:
    content = f.read()

new_content = content.replace(
    """    final chatStateAsync = ref.watch(chatProvider);
    final chatState = chatStateAsync.value;

    if (chatState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Real-world implementation would query user provider for available users in DB
    // Here we use existing chat threads simulating user profiles for demonstration
    final users = chatState.threads.where((t) => !t.isGroup && !t.isChannel && !t.isAiCoach).toList();

    final filteredUsers = users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.title.toLowerCase().contains(q) || (u.userHandle?.toLowerCase().contains(q) ?? false);
    }).toList();""",
    """    final chatStateAsync = ref.watch(chatProvider);
    final chatState = chatStateAsync.value;

    if (chatState == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Using existing chat threads simulating user profiles for demonstration
    final users = chatState.threads.where((t) => !t.isGroup && !t.isChannel && !t.isAiCoach).toList();

    final filteredUsers = users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.title.toLowerCase().contains(q) || (u.userHandle?.toLowerCase().contains(q) ?? false);
    }).toList();"""
)

with open("lib/features/interaction/connect/presentation/user_discovery_screen.dart", "w") as f:
    f.write(new_content)
