import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/input_scan/domain/entities/scan_failure.dart';
import 'package:pbl_semester5/features/input_scan/domain/entities/url_prediction.dart';
import 'package:pbl_semester5/features/input_scan/domain/repositories/url_predictor.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/submit_scan.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/scan_submission_controller.dart';
import 'package:pbl_semester5/features/input_scan/presentation/widgets/scan_preview_sheet.dart';
import 'package:pbl_semester5/theme/app_theme.dart';

/// Holds every prediction until the test releases it, so progress can be
/// observed one URL at a time.
class GatedPredictor implements UrlPredictor {
  GatedPredictor({this.failFirst = false});

  final bool failFirst;
  final List<Completer<UrlPrediction>> _pending = [];

  @override
  Future<UrlPrediction> predict(String url) {
    final completer = Completer<UrlPrediction>();
    _pending.add(completer);
    return completer.future;
  }

  void finish(int index, String url) => _pending[index].complete(
    UrlPrediction(
      scanId: 'scan-$index',
      url: url,
      category: 'Benign',
      score: 1,
      scoreKind: 'margin',
    ),
  );

  void fail(int index, {ScanFailureKind kind = ScanFailureKind.unknown}) =>
      _pending[index].completeError(
        ScanFailure('Model tidak menjawab.', kind: kind),
      );
}

void main() {
  late ScanSubmissionController controller;

  const urls = [
    'https://bca-verifikasi-akun.net/login',
    'https://contoh.com/promo',
  ];

  Widget processingScreen() =>
      ScanProcessingScreen(urls: urls, controller: controller);

  Future<GatedPredictor> open(
    WidgetTester tester, {
    bool asRoute = false,
  }) async {
    final predictor = GatedPredictor();
    controller = ScanSubmissionController(
      submitScan: const SubmitScan(),
      predictor: predictor,
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: linkGuardTheme(Brightness.light),
        home: asRoute
            ? Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () => Navigator.of(context).push<ScanSubmission>(
                      MaterialPageRoute(builder: (_) => processingScreen()),
                    ),
                    child: const Text('Mulai pemeriksaan'),
                  ),
                ),
              )
            : processingScreen(),
      ),
    );
    if (asRoute) await tester.tap(find.text('Mulai pemeriksaan'));
    await tester.pump();
    return predictor;
  }

  testWidgets('shows the shared header, progress and one row per link', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Pemeriksaan tautan'), findsOneWidget);
    expect(find.text('Memeriksa tautan.'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('0 dari 2 tautan selesai'), findsOneWidget);
    expect(find.text('Tautan yang diperiksa'), findsOneWidget);
    expect(find.text('bca-verifikasi-akun.net'), findsOneWidget);
    expect(find.text('https://bca-verifikasi-akun.net/login'), findsOneWidget);
    expect(find.text('Diperiksa'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Selesai'), findsNothing);
    expect(find.text('Batalkan'), findsOneWidget);
  });

  testWidgets('each finished link moves the progress and marks its row', (
    tester,
  ) async {
    final predictor = await open(tester);

    predictor.finish(0, 'https://bca-verifikasi-akun.net/login');
    await tester.pump();
    await tester.pump();

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 dari 2 tautan selesai'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Diperiksa'), findsOneWidget);
  });

  testWidgets('quick results wait for the two-second scan animation', (
    tester,
  ) async {
    final predictor = await open(tester, asRoute: true);

    predictor.finish(0, urls[0]);
    await tester.pump();
    predictor.finish(1, urls[1]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1999));

    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Menyiapkan hasil.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Mulai pemeriksaan'), findsOneWidget);
    expect(find.text('Menyiapkan hasil.'), findsNothing);
  });

  testWidgets('a slower check remains open with its real progress', (
    tester,
  ) async {
    final predictor = await open(tester, asRoute: true);

    predictor.finish(0, urls[0]);
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Memeriksa tautan.'), findsOneWidget);

    predictor.finish(1, urls[1]);
    await tester.pumpAndSettle();
    expect(find.text('Mulai pemeriksaan'), findsOneWidget);
  });

  testWidgets('cancelling leaves the page without waiting for the model', (
    tester,
  ) async {
    final predictor = await open(tester);

    await tester.ensureVisible(find.text('Batalkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();

    expect(find.text('Memeriksa tautan.'), findsNothing);
    predictor.finish(0, 'https://bca-verifikasi-akun.net/login');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a fatal failure offers a retry on the same layout', (
    tester,
  ) async {
    final predictor = await open(tester);

    predictor.fail(0, kind: ScanFailureKind.auth);
    await tester.pump();
    await tester.pump();

    expect(find.text('Pemeriksaan gagal'), findsOneWidget);
    expect(find.text('Model tidak menjawab.'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Memeriksa tautan.'), findsNothing);
  });
}
