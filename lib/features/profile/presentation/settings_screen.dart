import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/data/auth_provider.dart';
import '../data/user_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _questReminders = true;
  bool _eventAlerts = true;
  bool _aiSuggestions = true;
  bool _hapticFeedback = true;

  @override
  Widget build(BuildContext context) {
    final userState = (ref.watch(userProvider).value ?? UserState.initial());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Account Section
          const Text('Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.questBlue, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.questBlue,
                  child: Text(userState.initials, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(userState.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Lvl ${userState.level} • ${userState.currentXp} XP', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => _editProfileModal(context, userState.name),
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          const Text('Notifications & Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.questBlue, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: _questReminders,
                  title: const Text('Daily Quest Reminders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Get notified before daily quest reset', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  activeThumbColor: AppColors.questBlue,
                  onChanged: (val) => setState(() => _questReminders = val),
                ),
                const Divider(color: AppColors.border, height: 1),
                SwitchListTile(
                  value: _eventAlerts,
                  title: const Text('Event RSVP Alerts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Reminders 1 hour before scheduled events', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  activeThumbColor: AppColors.questBlue,
                  onChanged: (val) => setState(() => _eventAlerts = val),
                ),
                const Divider(color: AppColors.border, height: 1),
                SwitchListTile(
                  value: _aiSuggestions,
                  title: const Text('AI Guide Smart Insights', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Personalized connection recommendations', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  activeThumbColor: AppColors.questBlue,
                  onChanged: (val) => setState(() => _aiSuggestions = val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Experience Section
          const Text('Experience & Haptics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.questBlue, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: _hapticFeedback,
                  title: const Text('Haptic Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Vibrations on quest completions and level ups', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  activeThumbColor: AppColors.questBlue,
                  onChanged: (val) => setState(() => _hapticFeedback = val),
                ),
                const Divider(color: AppColors.border, height: 1),
                ListTile(
                  title: const Text('Theme Palette', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Midnight OLED (Active)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  trailing: const Icon(Icons.palette, color: AppColors.gold),
                  onTap: () => _showPaletteModal(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Organization Portal
          ListTile(
            tileColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            leading: const Icon(Icons.admin_panel_settings, color: AppColors.emerald),
            title: const Text('Organization & Host Portal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Access moderation and host tools', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward, color: AppColors.textMuted),
            onTap: () => context.push('/organization'),
          ),

          const SizedBox(height: 24),

          // Log out / Danger Zone
          ListTile(
            tileColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.border)),
            leading: const Icon(Icons.logout, color: AppColors.crimson),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.crimson, fontWeight: FontWeight.bold)),
            subtitle: const Text('Return to splash and landing screen', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            onTap: () => _showSignOutDialog(context),
          ),

          const SizedBox(height: 32),

          // App Info
          const Center(
            child: Text('Quest❗ • Version 2.0.0 (Build 42)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showPaletteModal(BuildContext context) {
    final themes = ['Midnight OLED (Default)', 'Deep Cyber Blue', 'Aurora Purple Nebula', 'Emerald Matrix'];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Theme Palette', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ...themes.map((t) => ListTile(
                  title: Text(t, style: const TextStyle(color: Colors.white)),
                  leading: Icon(Icons.color_lens, color: t.contains('Default') ? AppColors.gold : AppColors.questBlue),
                  trailing: t.contains('Default') ? const Icon(Icons.check_circle, color: AppColors.gold) : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.card,
                        content: Text('Applied theme: $t'),
                      ),
                    );
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out of Quest❗?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('You will need to sign back in to access your guild standings and XP.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson),
            onPressed: () async {
              Navigator.pop(ctx);
              // Sign out of Supabase session — GoRouter redirect guard handles navigation.
              await ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _editProfileModal(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(sheetCtx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Edit Profile Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final newName = nameCtrl.text.trim();
                  if (newName.isNotEmpty) {
                    // M-2 fix: actually persist the name change
                    ref.read(userProvider.notifier).updateName(newName);
                  }
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.surface,
                      content: Text('Profile updated successfully!'),
                    ),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

