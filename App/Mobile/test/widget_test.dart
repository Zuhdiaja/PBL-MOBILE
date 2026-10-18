// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_semester5/main.dart';

Future<void> openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  await tester.tap(find.text('Lewati'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login fits a narrow viewport without layout overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(150, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await openLogin(tester);

    expect(find.text('LinkGuard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo credentials sign in and invalid credentials are rejected', (
    WidgetTester tester,
  ) async {
    await openLogin(tester);

    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).at(0), 'wrong@email.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();
    expect(find.text('Email atau password salah.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'nadia@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Nadia'), findsOneWidget);
    expect(find.text('Mulai pindai'), findsOneWidget);
  });

  testWidgets('auth flow opens profile settings and returns', (
    WidgetTester tester,
  ) async {
    await openLogin(tester);

    expect(find.text('Masuk.'), findsOneWidget);
    await tester.ensureVisible(find.text('Daftar sekarang'));
    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Buat akun.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Nadia Putri');
    await tester.enterText(
      find.byType(TextField).at(1),
      'nadia-new@example.com',
    );
    await tester.enterText(find.byType(TextField).at(2), '123456');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Nadia'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nadia Putri'), findsOneWidget);
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi status laporan'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Nadia Putri'), findsOneWidget);
  });
}
