import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/input_scan/data/datasources/demo_url_predictor.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/prepare_scan_preview.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/submit_scan.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/scan_qr_controller.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/scan_submission_controller.dart';
import 'package:pbl_semester5/features/input_scan/presentation/pages/scan_qr_screen.dart';
import 'package:pbl_semester5/theme/app_theme.dart';

void main() {
  late ScanQrController controller;
  late ScanSubmissionController submission;
  late ValueChanged<String> emit;
  late bool cameraActive;

  setUp(() {
    controller = ScanQrController(
      prepareScanPreview: const PrepareScanPreview(),
      exampleUrl: 'https://contoh.com',
    );
    submission = ScanSubmissionController(
      submitScan: const SubmitScan(),
      predictor: const DemoUrlPredictor(),
    );
    cameraActive = false;
  });

  tearDown(() {
    controller.dispose();
    submission.dispose();
  });

  Widget fakeCamera(
    BuildContext context, {
    required ValueChanged<String> onDetect,
    required bool active,
  }) {
    emit = onDetect;
    cameraActive = active;
    return const SizedBox(height: 120, child: Text('kamera palsu'));
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: linkGuardTheme(Brightness.light),
        home: ScanQrScreen(
          controller: controller,
          submissionController: submission,
          onNavigate: (_) {},
          onSubmitted: (_) {},
          cameraBuilder: fakeCamera,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the camera and the example fallback', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Pindai kode QR'), findsOneWidget);
    expect(find.text('kamera palsu'), findsOneWidget);
    expect(find.text('Pindai contoh QR'), findsOneWidget);
    expect(cameraActive, isTrue);
  });

  testWidgets('a scanned link waits for confirmation before the check', (
    tester,
  ) async {
    await pumpScreen(tester);

    emit('https://pindai.example.test/promo');
    await tester.pumpAndSettle();

    expect(find.text('Lanjutkan pindai?'), findsOneWidget);
    expect(find.text('https://pindai.example.test/promo'), findsOneWidget);
    expect(find.text('Pemeriksaan selesai'), findsNothing);

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Lanjutkan pindai?'), findsNothing);
    expect(find.text('Pemeriksaan selesai'), findsOneWidget);
    expect(find.textContaining('berhasil diperiksa'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation keeps the camera ready', (
    tester,
  ) async {
    await pumpScreen(tester);

    emit('https://pindai.example.test/promo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Pemeriksaan selesai'), findsNothing);
    expect(find.text('kamera palsu'), findsOneWidget);
    expect(cameraActive, isTrue);
  });

  testWidgets('a QR without a link is refused with a clear message', (
    tester,
  ) async {
    await pumpScreen(tester);

    emit('WIFI:S:Rumah;T:WPA;P:rahasia;;');
    await tester.pumpAndSettle();

    expect(find.textContaining('Wi-Fi'), findsOneWidget);
    expect(find.text('Pemeriksaan selesai'), findsNothing);
  });

  testWidgets('the example button runs the same check', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Pindai contoh QR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lanjutkan'));
    await tester.pumpAndSettle();

    expect(find.text('Pemeriksaan selesai'), findsOneWidget);
  });
}
