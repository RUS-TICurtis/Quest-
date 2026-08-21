import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:quest/core/theme/app_colors_extension.dart';

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
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text('Settings & Preferences'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // Account Section
          Text(
            'Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.questBlue,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.colors.questBlue,
                  child: Text(
                    userState.initials,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userState.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Lvl ${userState.level} • ${userState.currentXp} XP',
                        style: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _editProfileModal(context, userState.name);
                  },
                  child: Text('Edit'),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Notifications Section
          Text(
            'Notifications & Alerts',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.questBlue,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          Material(
            color: context.colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: _questReminders,
                  title: Text(
                    'Daily Quest Reminders',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Get notified before daily quest reset',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                  ),
                  activeThumbColor: context.colors.questBlue,
                  onChanged: (val) => setState(() => _questReminders = val),
                ),
                Divider(color: context.colors.border, height: 1),
                SwitchListTile(
                  value: _eventAlerts,
                  title: Text(
                    'Event RSVP Alerts',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Reminders 1 hour before scheduled events',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                  ),
                  activeThumbColor: context.colors.questBlue,
                  onChanged: (val) => setState(() => _eventAlerts = val),
                ),
                Divider(color: context.colors.border, height: 1),
                SwitchListTile(
                  value: _aiSuggestions,
                  title: Text(
                    'AI Guide Smart Insights',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Personalized connection recommendations',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                  ),
                  activeThumbColor: context.colors.questBlue,
                  onChanged: (val) => setState(() => _aiSuggestions = val),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Experience Section
          Text(
            'Experience & Haptics',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.questBlue,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          Material(
            color: context.colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.colors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: _hapticFeedback,
                  title: Text(
                    'Haptic Feedback',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Vibrations on quest completions and level ups',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                  ),
                  activeThumbColor: context.colors.questBlue,
                  onChanged: (val) => setState(() => _hapticFeedback = val),
                ),
                Divider(color: context.colors.border, height: 1),
                ListTile(
                  title: Text(
                    'Theme Palette',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Midnight OLED (Active)',
                    style: TextStyle(color: context.colors.textMuted, fontSize: 12),
                  ),
                  trailing: Icon(Icons.palette, color: context.colors.gold),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showPaletteModal(context);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Organization Portal
          ListTile(
            tileColor: context.colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.colors.border),
            ),
            leading: Icon(
              Icons.admin_panel_settings,
              color: context.colors.emerald,
            ),
            title: Text(
              'Organization & Host Portal',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Access moderation and host tools',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
            trailing: Icon(
              Icons.arrow_forward,
              color: context.colors.textMuted,
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/organization');
            },
          ),

          SizedBox(height: 24),

          // Log out / Danger Zone
          ListTile(
            tileColor: context.colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.colors.border),
            ),
            leading: Icon(Icons.logout, color: context.colors.crimson),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: context.colors.crimson,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Return to splash and landing screen',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _showSignOutDialog(context);
            },
          ),

          SizedBox(height: 32),

          // App Info
          Center(
            child: Text(
              'Quest❗ • Version 2.0.0 (Build 42)',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showPaletteModal(BuildContext context) {
    final themes = [
      'Midnight OLED (Default)',
      'Deep Cyber Blue',
      'Aurora Purple Nebula',
      'Emerald Matrix',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme Palette',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            ...themes.map(
              (t) => ListTile(
                title: Text(
                  t,
                  style: TextStyle(color: context.colors.textPrimary),
                ),
                leading: Icon(
                  Icons.color_lens,
                  color: t.contains('Default')
                      ? context.colors.gold
                      : context.colors.questBlue,
                ),
                trailing: t.contains('Default')
                    ? Icon(Icons.check_circle, color: context.colors.gold)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: context.colors.card,
                      content: Text('Applied theme: $t'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Sign Out of Quest❗?',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You will need to sign back in to access your guild standings and XP.',
          style: TextStyle(color: context.colors.textPrimary70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.crimson),
            onPressed: () async {
              Navigator.pop(ctx);
              // Sign out of Supabase session — GoRouter redirect guard handles navigation.
              await ref.read(authProvider.notifier).signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
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
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile Name',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(labelText: 'Full Name'),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  final newName = nameCtrl.text.trim();
                  if (newName.isNotEmpty) {
                    // M-2 fix: actually persist the name change
                    ref.read(userProvider.notifier).updateName(newName);
                  }
                  Navigator.pop(sheetCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: context.colors.surface,
                      content: Text('Profile updated successfully!'),
                    ),
                  );
                },
                child: Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
