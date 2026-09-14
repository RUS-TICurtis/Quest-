with open("lib/features/interaction/connect/presentation/user_discovery_screen.dart", "r") as f:
    content = f.read()

new_content = content.replace(
    """    // Using existing chat threads simulating user profiles for demonstration
    final users = chatState.threads.where((t) => !t.isGroup && !t.isChannel && !t.isAiCoach).toList();""",
    """    // Users would be queried from Supabase dynamically using Supabase.instance.client.from('profiles').select().
    // Here we use chat threads that simulate available users.
    final users = chatState.threads.where((t) => !t.isGroup && !t.isChannel && !t.isAiCoach).toList();"""
)

with open("lib/features/interaction/connect/presentation/user_discovery_screen.dart", "w") as f:
    f.write(new_content)
