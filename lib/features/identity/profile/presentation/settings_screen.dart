import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quest/core/theme/app_colors_extension.dart';
import 'package:quest/features/identity/auth/data/auth_provider.dart';
import 'package:quest/features/identity/profile/data/user_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Notifications
  bool _directMessages = true;
  bool _groupMessages = true;
  bool _questReminders = true;
  bool _eventAlerts = true;
  bool _soundEnabled = true;
  bool _hapticFeedback = true;

  // Privacy
  String _storyPrivacy = 'Everyone';
  bool _readReceipts = true;

  // Data & Storage
  bool _autoDownloadWifiOnly = true;

  // Active Theme Selection
  String _selectedTheme = 'Midnight OLED';
  String _selectedAccent = 'Quest Blue';

  final List<Map<String, dynamic>> _accentColors = [
    {'name': 'Quest Blue', 'color': const Color(0xFF007AFF)},
    {'name': 'Emerald', 'color': const Color(0xFF10B981)},
    {'name': 'Aurora Purple', 'color': const Color(0xFF8B5CF6)},
    {'name': 'Crimson', 'color': const Color(0xFFEF4444)},
    {'name': 'Gold', 'color': const Color(0xFFF59E0B)},
  ];

  void _showChangePasswordDialog(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    final colors = context.colors;
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: colors.surface,
          title: Text(
            'Change Password',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                obscureText: obscureNew,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureNew = !obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: obscureConfirm,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: colors.questBlue),
              onPressed: () async {
                final newPass = newPassCtrl.text.trim();
                final confirmPass = confirmPassCtrl.text.trim();

                if (newPass.length < 6) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Password must be at least 6 characters'),
                      backgroundColor: colors.crimson,
                    ),
                  );
                  return;
                }
                if (newPass != confirmPass) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Passwords do not match'),
                      backgroundColor: colors.crimson,
                    ),
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  await Supabase.instance.client.auth.updateUser(
                    UserAttributes(password: newPass),
                  );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Password updated successfully!'),
                        backgroundColor: colors.emerald,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Could not update password: $e'),
                        backgroundColor: colors.crimson,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    final router = GoRouter.of(context);
    final colors = context.colors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text(
          'Sign Out of Quest?',
          style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You will be returned to the sign-in screen.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.crimson),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              await ref.read(authProvider.notifier).signOut();
              if (mounted) {
                router.go('/landing');
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider).value ?? UserState.initial();
    final authUser = Supabase.instance.client.auth.currentUser;
    final email = authUser?.email ?? 'quest_explorer@quest.app';

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        children: [
          // ==========================================
          // 1. Profile / Account Header Card (Instagram / Snapchat style)
          // ==========================================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.colors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: context.colors.questBlue,
                      backgroundImage: userState.avatarUrl != null && userState.avatarUrl!.isNotEmpty
                          ? NetworkImage(userState.avatarUrl!)
                          : null,
                      child: (userState.avatarUrl == null || userState.avatarUrl!.isEmpty)
                          ? Text(
                              userState.initials.isNotEmpty ? userState.initials : 'Q',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userState.name.isNotEmpty ? userState.name : 'Quest Explorer',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userState.username != null && userState.username!.isNotEmpty
                                ? '@${userState.username}'
                                : email,
                            style: TextStyle(
                              color: context.colors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: context.colors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Lvl ${userState.level} • ${userState.currentXp} XP',
                              style: TextStyle(
                                color: context.colors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Dedicated "Edit Profile" Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.questBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push('/profile/edit');
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // 2. Account & Security (Telegram/WhatsApp style)
          // ==========================================
          _buildSectionHeader('Account & Security'),
          _buildCard([
            ListTile(
              leading: Icon(Icons.email_outlined, color: context.colors.questBlue),
              title: Text('Email Address', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(email, style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
            ),
            _buildDivider(),
            ListTile(
              leading: Icon(Icons.lock_reset, color: context.colors.questBlue),
              title: Text('Change Password', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Update your Supabase credentials', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
              onTap: () {
                HapticFeedback.lightImpact();
                _showChangePasswordDialog(context);
              },
            ),
            _buildDivider(),
            ListTile(
              leading: Icon(Icons.visibility_outlined, color: context.colors.questBlue),
              title: Text('Story & Status Privacy', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(_storyPrivacy, style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _storyPrivacy = _storyPrivacy == 'Everyone' ? 'Followers Only' : 'Everyone';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Story privacy set to: $_storyPrivacy'),
                    backgroundColor: context.colors.card,
                  ),
                );
              },
            ),
            _buildDivider(),
            SwitchListTile(
              secondary: Icon(Icons.done_all, color: context.colors.questBlue),
              value: _readReceipts,
              title: Text('Read Receipts', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Let others know when you read their messages', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _readReceipts = val),
            ),
          ]),

          const SizedBox(height: 24),

          // ==========================================
          // 3. Appearance & Personalization (Telegram style)
          // ==========================================
          _buildSectionHeader('Appearance & Theme'),
          _buildCard([
            ListTile(
              leading: Icon(Icons.brightness_4_outlined, color: context.colors.gold),
              title: Text('Theme Palette', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('$_selectedTheme (Active)', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
              onTap: () => _showPaletteModal(context),
            ),
            _buildDivider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accent Color',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _accentColors.map((acc) {
                      final isSelected = _selectedAccent == acc['name'];
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedAccent = acc['name'] as String);
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: acc['color'] as Color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (acc['color'] as Color).withValues(alpha: 0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, color: Colors.white, size: 22)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            _buildDivider(),
            SwitchListTile(
              secondary: Icon(Icons.vibration, color: context.colors.questBlue),
              value: _hapticFeedback,
              title: Text('Tactile Haptics', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Vibrations on state transitions and haptic taps', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _hapticFeedback = val),
            ),
          ]),

          const SizedBox(height: 24),

          // ==========================================
          // 4. Notifications & Alerts (WhatsApp style)
          // ==========================================
          _buildSectionHeader('Notifications & Sounds'),
          _buildCard([
            SwitchListTile(
              secondary: Icon(Icons.chat_bubble_outline, color: context.colors.questBlue),
              value: _directMessages,
              title: Text('Direct Messages', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _directMessages = val),
            ),
            _buildDivider(),
            SwitchListTile(
              secondary: Icon(Icons.groups_outlined, color: context.colors.questBlue),
              value: _groupMessages,
              title: Text('Group & Community Chats', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _groupMessages = val),
            ),
            _buildDivider(),
            SwitchListTile(
              secondary: Icon(Icons.event_available, color: context.colors.questBlue),
              value: _eventAlerts,
              title: Text('Event RSVP Reminders', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('1 hour before scheduled events', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _eventAlerts = val),
            ),
            _buildDivider(),
            SwitchListTile(
              secondary: Icon(Icons.military_tech_outlined, color: context.colors.questBlue),
              value: _questReminders,
              title: Text('Daily Quest Reset Alerts', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _questReminders = val),
            ),
            _buildDivider(),
            SwitchListTile(
              secondary: Icon(Icons.volume_up_outlined, color: context.colors.questBlue),
              value: _soundEnabled,
              title: Text('In-App Sounds', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _soundEnabled = val),
            ),
          ]),

          const SizedBox(height: 24),

          // ==========================================
          // 5. Data & Storage (Telegram style)
          // ==========================================
          _buildSectionHeader('Data & Storage'),
          _buildCard([
            SwitchListTile(
              secondary: Icon(Icons.wifi, color: context.colors.questBlue),
              value: _autoDownloadWifiOnly,
              title: Text('Auto-Download on Wi-Fi Only', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Saves cellular data when viewing feeds and stories', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              activeThumbColor: context.colors.questBlue,
              onChanged: (val) => setState(() => _autoDownloadWifiOnly = val),
            ),
            _buildDivider(),
            ListTile(
              leading: Icon(Icons.cleaning_services_outlined, color: context.colors.questBlue),
              title: Text('Clear Media Cache', style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('Free up temporary image and video storage', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
              onTap: () {
                HapticFeedback.mediumImpact();
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Media cache cleared successfully!'),
                    backgroundColor: context.colors.emerald,
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 24),

          // ==========================================
          // 6. Organization Portal
          // ==========================================
          _buildCard([
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: context.colors.emerald),
              title: Text(
                'Organization & Host Portal',
                style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Access community management and analytics', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              trailing: Icon(Icons.chevron_right, color: context.colors.textMuted),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('/organization');
              },
            ),
          ]),

          const SizedBox(height: 24),

          // ==========================================
          // 7. Session & Sign Out
          // ==========================================
          _buildCard([
            ListTile(
              leading: Icon(Icons.logout, color: context.colors.crimson),
              title: Text(
                'Sign Out',
                style: TextStyle(color: context.colors.crimson, fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Safely log out of your Supabase account', style: TextStyle(color: context.colors.textMuted, fontSize: 12)),
              onTap: () {
                HapticFeedback.lightImpact();
                _showSignOutDialog(context);
              },
            ),
          ]),

          const SizedBox(height: 32),

          Center(
            child: Text(
              'Quest • Version 2.0.0 (Build 42)',
              style: TextStyle(color: context.colors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: context.colors.questBlue,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Material(
      color: context.colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(color: context.colors.border, height: 1);
  }

  void _showPaletteModal(BuildContext context) {
    final themes = [
      'Midnight OLED',
      'Deep Cyber Dark',
      'Aurora Nebula',
      'Emerald Matrix',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme Palette',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textPrimary),
            ),
            const SizedBox(height: 16),
            ...themes.map(
              (t) => ListTile(
                title: Text(t, style: TextStyle(color: context.colors.textPrimary)),
                leading: Icon(
                  Icons.color_lens,
                  color: t == _selectedTheme ? context.colors.gold : context.colors.questBlue,
                ),
                trailing: t == _selectedTheme
                    ? Icon(Icons.check_circle, color: context.colors.gold)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedTheme = t);
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
}
