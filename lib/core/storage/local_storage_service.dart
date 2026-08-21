import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'localStorageServiceProvider must be overridden in ProviderScope',
  );
});

class LocalStorageService {
  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // String keys for specific data
  static const String keyProfileName = 'profile_name';
  static const String keyProfileAvatarUrl = 'profile_avatar_url';
  static const String keyProfileXp = 'profile_xp';
  static const String keyProfileLevel = 'profile_level';

  // --- Profile Methods ---

  Future<void> saveProfile({
    required String name,
    required String avatarUrl,
    required int xp,
    required int level,
  }) async {
    await _prefs.setString(keyProfileName, name);
    await _prefs.setString(keyProfileAvatarUrl, avatarUrl);
    await _prefs.setInt(keyProfileXp, xp);
    await _prefs.setInt(keyProfileLevel, level);
  }

  Map<String, dynamic>? getProfile() {
    final name = _prefs.getString(keyProfileName);
    if (name == null) return null; // No saved profile

    return {
      'name': name,
      'avatarUrl': _prefs.getString(keyProfileAvatarUrl) ?? '',
      'xp': _prefs.getInt(keyProfileXp) ?? 0,
      'level': _prefs.getInt(keyProfileLevel) ?? 1,
    };
  }

  // Generic key-value storage methods
  String? getString(String key) {
    return _prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }
}
