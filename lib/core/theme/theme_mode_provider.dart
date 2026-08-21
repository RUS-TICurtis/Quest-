import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage_service.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'app_theme_mode';

  @override
  ThemeMode build() {
    final storage = ref.watch(localStorageServiceProvider);
    return _loadThemeMode(storage);
  }

  static ThemeMode _loadThemeMode(LocalStorageService storage) {
    final savedTheme = storage.getString(_themeKey);
    if (savedTheme == 'light') return ThemeMode.light;
    if (savedTheme == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    String modeString = 'system';
    if (mode == ThemeMode.light) modeString = 'light';
    if (mode == ThemeMode.dark) modeString = 'dark';
    
    final storage = ref.read(localStorageServiceProvider);
    storage.setString(_themeKey, modeString);
  }

  void toggleTheme() {
    if (state == ThemeMode.dark) {
      setThemeMode(ThemeMode.light);
    } else if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.system);
    } else {
      setThemeMode(ThemeMode.dark);
    }
  }
}
