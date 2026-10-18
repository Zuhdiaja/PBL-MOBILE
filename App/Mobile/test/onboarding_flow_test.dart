import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pbl_semester5/main.dart';
import 'package:pbl_semester5/theme/app_colors.dart';
import 'package:pbl_semester5/theme/app_theme.dart';

void main() {
  const light = AppPalette(false);
  const dark = AppPalette(true);

  BoxDecoration cardDecoration(WidgetTester tester, String key) =>
      tester.widget<Container>(find.byKey(ValueKey(key))).decoration
          as BoxDecoration;

  testWidgets('onboarding supports next, back, and continue to login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Kenali tautan sebelum dibuka.'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Berikutnya'), findsOneWidget);
    expect(
      tester
          .widget<Scaffold>(
            find.descendant(
              of: find.byType(OnboardingPage),
              matching: find.byType(Scaffold),
            ),
          )
          .backgroundColor,
      light.scanner,
    );
    expect(
      cardDecoration(tester, 'onboarding-artwork').color,
      light.artworkSurface,
    );
    expect(
      cardDecoration(tester, 'onboarding-artwork').border!.top.color,
      light.artworkLine,
    );
    expect(
      cardDecoration(tester, 'onboarding-status-card').color,
      light.artworkSurface,
    );
    expect(
      cardDecoration(tester, 'onboarding-status-card').border!.top.color,
      light.artworkLine,
    );
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Deteksi ancaman lebih awal.'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(find.byKey(const ValueKey('onboarding-feature-icon')))
          .icon,
      Icons.verified_user_outlined,
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'ikon fitur dan plat ikon memakai token tema',
    );

    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Kenali tautan sebelum dibuka.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Pantau hasil pindai Anda.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skip opens login on a narrow screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(150, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Lewati'), findsOneWidget);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding memakai token artwork pada mode gelap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: linkGuardTheme(Brightness.dark),
        home: OnboardingPage(onComplete: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      cardDecoration(tester, 'onboarding-artwork').color,
      dark.artworkSurface,
    );
    expect(
      cardDecoration(tester, 'onboarding-artwork').border!.top.color,
      dark.artworkLine,
    );
    expect(
      cardDecoration(tester, 'onboarding-status-card').color,
      dark.artworkSurface,
    );
    expect(dark.artworkSurface, isNot(Colors.white));
    expect(dark.artworkLine, isNot(light.artworkLine));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    expect(find.text('Deteksi ancaman lebih awal.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
