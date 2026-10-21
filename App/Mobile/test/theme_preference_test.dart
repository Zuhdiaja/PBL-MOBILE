import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/app/auth_dependencies.dart';
import 'package:pbl_semester5/app/theme_dependencies.dart';
import 'package:pbl_semester5/features/auth/presentation/pages/settings_page.dart';
import 'package:pbl_semester5/main.dart';
import 'package:pbl_semester5/theme/app_theme.dart';
import 'package:pbl_semester5/theme/theme_controller.dart';
import 'package:pbl_semester5/theme/theme_preference_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'scan_flow_test.dart' show tapVisible;

class _BrokenStore implements ThemePreferenceStore {
  @override
  Future<ThemeMode> read() async => throw StateError('read failed');

  @override
  Future<void> write(ThemeMode mode) async => throw StateError('write failed');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaults to the device theme', () {
    expect(ThemeController(MemoryThemeStore()).mode, ThemeMode.system);
  });

  test('select persists and restores the choice', () async {
    final store = MemoryThemeStore();
    final controller = ThemeController(store);
    addTearDown(controller.dispose);

    await controller.select(ThemeMode.dark);
    expect(controller.mode, ThemeMode.dark);

    final restored = ThemeController(store);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.mode, ThemeMode.dark);
  });

  test('store round-trips every mode', () async {
    final store = SharedPreferencesThemeStore();
    for (final mode in ThemeMode.values) {
      await store.write(mode);
      expect(await store.read(), mode);
    }
  });

  test('unknown stored value falls back to the device theme', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    expect(await SharedPreferencesThemeStore().read(), ThemeMode.system);
  });

  test('a failing store never breaks the session choice', () async {
    final controller = ThemeController(_BrokenStore());
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.mode, ThemeMode.system);

    await controller.select(ThemeMode.light);
    expect(controller.mode, ThemeMode.light);
  });

  testWidgets(
    'settings offers system, light and dark and remembers the choice',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final theme = ThemeDependencies();
      await theme.controller.load();
      await tester.pumpWidget(MyApp(theme: theme.controller));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Masuk'));
      await tapVisible(tester, find.text('Profil').last);
      await tapVisible(tester, find.text('Pengaturan'));

      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Terang'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );

      await tapVisible(tester, find.text('Gelap'));
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      await tapVisible(tester, find.text('Sistem'));
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );

      await tapVisible(tester, find.text('Gelap'));

      final restarted = ThemeDependencies();
      await restarted.controller.load();
      addTearDown(restarted.controller.dispose);
      expect(restarted.controller.mode, ThemeMode.dark);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('theme selector fits a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthDependencies();
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: linkGuardTheme(Brightness.light),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: SettingsPage(controller: auth.settings, onNavigate: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sistem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
