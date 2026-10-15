import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/main.dart';
import 'package:pbl_semester5/app/scan_results_dependencies.dart';
import 'package:pbl_semester5/features/scan_results/presentation/pages/report_prediction_screen.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/prediction_report.dart';
import 'package:pbl_semester5/theme/app_theme.dart';
import 'package:pbl_semester5/theme/app_colors.dart';

import 'scan_flow_test.dart' show openApp, tapVisible;

Future<void> signIn(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const MyApp());
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(1), '123456');
  await tapVisible(tester, find.widgetWithText(FilledButton, 'Masuk'));
}

void main() {
  testWidgets('theme selection retains the session and URL draft', (
    tester,
  ) async {
    await signIn(tester);
    await tapVisible(tester, find.text('Mulai pindai'));
    await tester.enterText(
      find.byType(TextFormField),
      'https://contoh.com/draft',
    );
    await tapVisible(tester, find.text('Profil').last);
    await tapVisible(tester, find.text('Pengaturan'));
    await tapVisible(tester, find.text('Gelap'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Nadia Putri'), findsOneWidget);
    await tapVisible(tester, find.text('Pindai').last);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'https://contoh.com/draft',
    );
    expect(
      Theme.of(tester.element(find.byType(TextFormField))).brightness,
      Brightness.dark,
    );
    expect(
      tester.element(find.byType(TextFormField)).colors.paper,
      const Color(0xFF101D2D),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('password visibility preserves the typed password', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'a-long-password');
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isTrue,
    );
    await tapVisible(tester, find.byTooltip('Tampilkan kata sandi'));
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      'a-long-password',
    );
  });
  testWidgets('history combines search, safety scope and category', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.text('Riwayat').last);
    await tester.enterText(find.byType(TextField), 'not-in-the-history');
    await tester.pumpAndSettle();
    expect(find.text('0 hasil'), findsOneWidget);
    expect(find.textContaining('Tidak ada tautan yang cocok'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Aman').first);
    expect(find.text('2 hasil'), findsOneWidget);
    await tapVisible(tester, find.text('Semua').first);
    await tapVisible(tester, find.text('Semua kategori'));
    await tapVisible(tester, find.text('Phishing').last);
    expect(find.text('2 hasil'), findsOneWidget);
    await tapVisible(tester, find.text('Arti kategori'));
    expect(
      find.textContaining('menyamar untuk mengambil data pribadi'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('cancel preparation returns to the unchanged URL form', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.text('Mulai pindai'));
    await tester.enterText(
      find.byType(TextFormField),
      'https://contoh.com/cancel',
    );
    await tester.ensureVisible(find.text('Periksa URL'));
    await tester.tap(find.text('Periksa URL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    expect(find.text('Pratinjau pemeriksaan'), findsNothing);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller!.text,
      'https://contoh.com/cancel',
    );
  });
  for (final safe in [false, true]) {
    testWidgets('correction for safe=$safe validates notes and category', (
      tester,
    ) async {
      final dependencies = ScanResultsDependencies();
      await dependencies.scanResults.load();
      final result = dependencies.scanResults.results.firstWhere(
        (r) => r.isSafe == safe,
      );
      final controller = dependencies.createReportController(result);
      addTearDown(controller.dispose);
      addTearDown(dependencies.dispose);
      var submitted = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: linkGuardTheme(Brightness.light),
          home: ReportPredictionScreen(
            controller: controller,
            onSubmitted: () => submitted = true,
          ),
        ),
      );
      expect(
        controller.type,
        safe ? ReportType.falseNegative : ReportType.falsePositive,
      );
      expect(controller.category, safe ? isEmpty : 'Aman / Benign');
      await tapVisible(tester, find.text('Kirim laporan'));
      expect(submitted, isFalse);
      expect(
        find.text('Tambahkan catatan untuk menjelaskan koreksi.'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField),
        'Bukti pendukung koreksi.',
      );
      if (safe) {
        await tapVisible(tester, find.text('Kirim laporan'));
        expect(submitted, isFalse);
        expect(
          find.text('Pilih kategori yang benar terlebih dahulu.'),
          findsOneWidget,
        );
        await tapVisible(tester, find.text('Pilih kategori'));
        expect(find.text('Aman / Benign'), findsNothing);
        await tapVisible(tester, find.text('Phishing').last);
      }
      await tapVisible(tester, find.text('Kirim laporan'));
      expect(submitted, isTrue);
    });
  }
}
