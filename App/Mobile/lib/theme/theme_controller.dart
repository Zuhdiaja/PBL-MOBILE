import 'package:flutter/material.dart';

import 'theme_preference_store.dart';

/// Owns the selected [ThemeMode] and keeps it in the injected store.
class ThemeController extends ChangeNotifier {
  ThemeController(this._store);

  final ThemePreferenceStore _store;

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  /// Restores the saved choice. Falls back to following the device theme.
  Future<void> load() async {
    try {
      _mode = await _store.read();
    } catch (_) {
      _mode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Applies the choice immediately, then persists it.
  Future<void> select(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      await _store.write(mode);
    } catch (_) {
      // Keeping the session choice matters more than the failed write.
    }
  }
}
