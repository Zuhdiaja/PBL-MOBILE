// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_semester5/main.dart';

void main() {
  testWidgets('login fits a narrow viewport without layout overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(150, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    expect(find.text('linkguard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo credentials sign in and invalid credentials are rejected', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(TextField), findsNWidgets(2));
    await tester.enterText(find.byType(TextField).at(0), 'wrong@email.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();
    expect(find.text('Email atau password salah.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'nadia@gmail.com');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Nadia'), findsOneWidget);
    expect(find.text('Mulai scan'), findsOneWidget);
  });

  testWidgets('auth flow opens profile settings and returns', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Selamat datang kembali'), findsOneWidget);
    await tester.tap(find.text('Daftar sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Buat akun baru'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Halo, Nadia'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Nadia Putri'), findsOneWidget);
    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();

    expect(find.text('Notifikasi status laporan'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Nadia Putri'), findsOneWidget);
  });
}
