import '../theme/theme_controller.dart';
import '../theme/theme_preference_store.dart';

/// Composition root for the app-wide theme preference.
///
/// The concrete device store stays here so widgets never import
/// `shared_preferences` directly. The controller is handed to `MyApp`, which
/// owns its disposal for the lifetime of the app.
class ThemeDependencies {
  ThemeDependencies({ThemePreferenceStore? store})
    : controller = ThemeController(store ?? SharedPreferencesThemeStore());

  final ThemeController controller;
}
