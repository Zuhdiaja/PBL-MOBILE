import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme choice across app launches.
abstract class ThemePreferenceStore {
  Future<ThemeMode> read();

  Future<void> write(ThemeMode mode);
}

/// Device storage backed by `shared_preferences`.
class SharedPreferencesThemeStore implements ThemePreferenceStore {
  static const _key = 'theme_mode';

  @override
  Future<ThemeMode> read() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_key)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> write(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}

/// In-memory store used when no device storage is available.
class MemoryThemeStore implements ThemePreferenceStore {
  ThemeMode _mode = ThemeMode.system;

  @override
  Future<ThemeMode> read() async => _mode;

  @override
  Future<void> write(ThemeMode mode) async => _mode = mode;
}
