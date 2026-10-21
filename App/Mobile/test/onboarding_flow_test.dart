import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pbl_semester5/main.dart';
import 'package:pbl_semester5/theme/app_colors.dart';
import 'package:pbl_semester5/theme/app_theme.dart';

Future<void> showOnboarding(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  Brightness brightness = Brightness.light,
  double scale = 1,
  bool reduceMotion = false,
  VoidCallback? onComplete,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: linkGuardTheme(brightness),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          disableAnimations: reduceMotion,
        ),
        child: child!,
      ),
      home: OnboardingPage(onComplete: onComplete ?? () {}),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'next, back, swipe, and finish keep the current step synchronized',
    (tester) async {
      var completed = 0;
      await showOnboarding(tester, onComplete: () => completed++);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('onboarding-artwork-0')))
            .height,
        greaterThan(300),
      );
      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Jangan buru-buru.'), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(RegExp(r'^Kenali tautan\s+sebelum dibuka\.$')),
        findsOneWidget,
      );
      await tester.drag(find.byType(PageView), const Offset(-390, 0));
      await tester.pumpAndSettle();
      expect(find.textContaining('Jangan buru-buru.'), findsOneWidget);
      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pemeriksaan lalu,'), findsOneWidget);
      expect(completed, 0);
      await tester.tap(find.text('Mulai sekarang'));
      await tester.pumpAndSettle();
      expect(completed, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('regression: compact onboarding uses Indonesian navigation', (
    tester,
  ) async {
    await showOnboarding(tester, size: const Size(320, 700));
    expect(find.text('Next'), findsNothing);
    expect(find.text('Berikutnya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('regression: system Back returns to the previous step', (
    tester,
  ) async {
    await showOnboarding(tester);
    await tester.tap(find.text('Berikutnya'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.textContaining(RegExp(r'^Kenali tautan\s+sebelum dibuka\.$')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('all slides remain usable with large text in $brightness', (
      tester,
    ) async {
      await showOnboarding(
        tester,
        size: const Size(320, 568),
        brightness: brightness,
        scale: 2,
        reduceMotion: true,
      );
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        AppPalette(brightness == Brightness.dark).paper,
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Berikutnya'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Mulai sekarang'), findsOneWidget);
    });
  }

  testWidgets(
    'progress is announced and images do not repeat screen-reader copy',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await showOnboarding(tester);
      expect(find.bySemanticsLabel('Halaman 1 dari 3'), findsOneWidget);
      await tester.tap(find.text('Berikutnya'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Halaman 2 dari 3'), findsOneWidget);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  for (var step = 0; step < 3; step++) {
    testWidgets('skip from step $step completes once', (tester) async {
      var completed = 0;
      await showOnboarding(tester, onComplete: () => completed++);
      for (var i = 0; i < step; i++) {
        await tester.tap(find.text('Berikutnya'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Lewati'));
      await tester.tap(find.text('Lewati'));
      expect(completed, 1);
    });
  }

  testWidgets('skip still opens the existing login on a very narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(150, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
