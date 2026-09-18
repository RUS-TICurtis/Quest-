import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'localStorageServiceProvider must be overridden in ProviderScope',
  );
});

/// SharedPreferences-backed storage for scalar user data and UI settings.
///
/// Caching layer assignment: this service handles small scalar values only.
/// Structured data (chat, feed, profiles, stories) lives in Hive / Isar.
class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ── Profile keys ─────────────────────────────────────────────────────────
  static const String keyProfileName = 'profile_name';
  static const String keyProfileAvatarUrl = 'profile_avatar_url';
  static const String keyProfileXp = 'profile_xp';
  static const String keyProfileLevel = 'profile_level';
  static const String keyProfileUsername = 'profile_username';
  static const String keyProfileBio = 'profile_bio';

  // ── Notification keys ────────────────────────────────────────────────────
  static const String keyNotifyDMs = 'notify_dms';
  static const String keyNotifyGroups = 'notify_groups';
  static const String keyNotifyEvents = 'notify_events';
  static const String keyNotifyQuests = 'notify_quests';
  static const String keySoundEnabled = 'sound_enabled';
  static const String keyHapticEnabled = 'haptic_enabled';

  // ── Privacy keys ─────────────────────────────────────────────────────────
  static const String keyStoryPrivacy = 'story_privacy';
  static const String keyReadReceipts = 'read_receipts';

  // ── Data & Storage keys ──────────────────────────────────────────────────
  static const String keyWifiOnly = 'wifi_only_download';

  // ── Appearance keys ──────────────────────────────────────────────────────
  static const String keySelectedTheme = 'selected_theme';
  static const String keySelectedAccent = 'selected_accent';

  // ── Profile methods ───────────────────────────────────────────────────────

  Future<void> saveProfile({
    required String name,
    required String avatarUrl,
    required int xp,
    required int level,
    String? username,
    String? bio,
  }) async {
    await _prefs.setString(keyProfileName, name);
    await _prefs.setString(keyProfileAvatarUrl, avatarUrl);
    await _prefs.setInt(keyProfileXp, xp);
    await _prefs.setInt(keyProfileLevel, level);
    if (username != null) await _prefs.setString(keyProfileUsername, username);
    if (bio != null) await _prefs.setString(keyProfileBio, bio);
  }

  Map<String, dynamic>? getProfile() {
    final name = _prefs.getString(keyProfileName);
    if (name == null) return null;

    return {
      'name': name,
      'avatarUrl': _prefs.getString(keyProfileAvatarUrl) ?? '',
      'xp': _prefs.getInt(keyProfileXp) ?? 0,
      'level': _prefs.getInt(keyProfileLevel) ?? 1,
      'username': _prefs.getString(keyProfileUsername),
      'bio': _prefs.getString(keyProfileBio),
    };
  }

  // ── Typed generic accessors ───────────────────────────────────────────────

  bool getBool(String key, {bool defaultValue = true}) =>
      _prefs.getBool(key) ?? defaultValue;

  Future<void> setBool(String key, bool value) async =>
      _prefs.setBool(key, value);

  int getInt(String key, {int defaultValue = 0}) =>
      _prefs.getInt(key) ?? defaultValue;

  Future<void> setInt(String key, int value) async =>
      _prefs.setInt(key, value);

  String? getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) async =>
      _prefs.setString(key, value);

  // ── Convenience settings accessors ────────────────────────────────────────

  // Notifications
  bool get notifyDMs => getBool(keyNotifyDMs, defaultValue: true);
  bool get notifyGroups => getBool(keyNotifyGroups, defaultValue: true);
  bool get notifyEvents => getBool(keyNotifyEvents, defaultValue: true);
  bool get notifyQuests => getBool(keyNotifyQuests, defaultValue: true);
  bool get soundEnabled => getBool(keySoundEnabled, defaultValue: true);
  bool get hapticEnabled => getBool(keyHapticEnabled, defaultValue: true);

  // Privacy
  String get storyPrivacy =>
      _prefs.getString(keyStoryPrivacy) ?? 'Everyone';
  bool get readReceipts => getBool(keyReadReceipts, defaultValue: true);

  // Data
  bool get wifiOnly => getBool(keyWifiOnly, defaultValue: true);

  // Appearance
  String get selectedTheme =>
      _prefs.getString(keySelectedTheme) ?? 'Midnight OLED';
  String get selectedAccent =>
      _prefs.getString(keySelectedAccent) ?? 'Quest Blue';
}
