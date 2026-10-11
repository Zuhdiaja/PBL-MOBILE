import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_semester5/features/input_scan/domain/entities/input_scan_failure.dart';
import 'package:pbl_semester5/features/input_scan/domain/entities/recent_scan.dart';
import 'package:pbl_semester5/features/input_scan/domain/repositories/clipboard_repository.dart';
import 'package:pbl_semester5/features/input_scan/domain/repositories/recent_scans_repository.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/prepare_scan_preview.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/home_controller.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/scan_qr_controller.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/scan_url_controller.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/share_link_controller.dart';

class FakeClipboardRepository implements ClipboardRepository {
  ClipboardResult result = (text: 'https://contoh.com', failure: null);
  Completer<ClipboardResult>? pending;

  @override
  Future<ClipboardResult> readText() async => pending?.future ?? result;
}

class FakeRecentScansRepository implements RecentScansRepository {
  final items = <RecentScan>[
    const RecentScan(
      id: 'scan-1',
      url: 'docs.example.com',
      category: 'Benign',
      isSafe: true,
      scanTime: '18 Sep 2026, 09:12 WIB',
    ),
  ];

  @override
  List<RecentScan> getRecentScans() => items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const prepare = PrepareScanPreview();

  test(
    'home reads a repository snapshot instead of depending on demo data',
    () {
      final repository = FakeRecentScansRepository();
      final controller = HomeController(repository);
      repository.items.clear();
      expect(controller.recentScans.single.id, 'scan-1');
      expect(() => controller.recentScans.clear(), throwsUnsupportedError);
    },
  );

  testWidgets('URL controller keeps drafts and enforces field limits', (
    tester,
  ) async {
    final controller = ScanUrlController(
      clipboardRepository: FakeClipboardRepository(),
      prepareScanPreview: prepare,
    );
    addTearDown(controller.dispose);
    controller.fields.first.text = 'https://contoh.com/draft';
    for (var i = 0; i < 8; i++) {
      controller.addUrl();
    }
    expect(controller.fields.length, 5);
    expect(controller.canAddUrl, isFalse);
    controller.removeUrl(1);
    expect(controller.fields.length, 4);
    expect(controller.fields.first.text, 'https://contoh.com/draft');
    while (controller.fields.length > 1) {
      controller.removeUrl(1);
    }
    controller.removeUrl(0);
    expect(controller.fields.length, 1);
    expect(controller.preparePreview().failure, isNull);
    await tester.pump();
  });

  test('paste success fills the draft and failure preserves it', () async {
    final repository = FakeClipboardRepository();
    final controller = ScanUrlController(
      clipboardRepository: repository,
      prepareScanPreview: prepare,
    );
    addTearDown(controller.dispose);
    expect(await controller.pasteIntoFirstField(), isNull);
    expect(controller.fields.first.text, 'https://contoh.com');
    repository.result = (
      text: null,
      failure: const InputScanFailure('Clipboard tidak tersedia.'),
    );
    expect(await controller.pasteIntoFirstField(), 'Clipboard tidak tersedia.');
    expect(controller.fields.first.text, 'https://contoh.com');
  });

  testWidgets('late paste does not write into a removed field', (tester) async {
    final repository = FakeClipboardRepository()
      ..pending = Completer<ClipboardResult>();
    final controller = ScanUrlController(
      clipboardRepository: repository,
      prepareScanPreview: prepare,
    );
    addTearDown(controller.dispose);
    controller.addUrl();
    final pending = controller.paste(controller.fields.last);
    controller.removeUrl(1);
    await tester.pump();
    repository.pending!.complete((
      text: 'https://late.example.com',
      failure: null,
    ));
    expect(await pending, isNull);
    expect(controller.fields.single.text, isEmpty);
  });

  test('late paste is ignored after the URL controller is disposed', () async {
    final repository = FakeClipboardRepository()
      ..pending = Completer<ClipboardResult>();
    final controller = ScanUrlController(
      clipboardRepository: repository,
      prepareScanPreview: prepare,
    );
    final pending = controller.pasteIntoFirstField();
    controller.dispose();
    repository.pending!.complete((
      text: 'https://late.example.com',
      failure: null,
    ));
    expect(await pending, isNull);
  });

  test(
    'share example, edits and paste use injected input and domain validation',
    () async {
      final repository = FakeClipboardRepository();
      final controller = ShareLinkController(
        clipboardRepository: repository,
        prepareScanPreview: prepare,
        exampleUrl: 'https://shared.example.com/article',
      );
      addTearDown(controller.dispose);
      controller.useExample();
      expect(controller.usingExample, isTrue);
      expect(controller.host, 'shared.example.com');
      controller.field.text = 'invalid';
      controller.markEdited();
      expect(controller.usingExample, isFalse);
      expect(controller.host, isNull);
      expect(controller.preparePreview().failure, isNotNull);
      expect((await controller.paste())!.failure, isNull);
      expect(controller.url, 'https://contoh.com');
      expect(
        controller.preparePreview().preview!.urls.single.value,
        controller.url,
      );
    },
  );

  test('share clipboard failure keeps the example and its label', () async {
    final repository = FakeClipboardRepository()
      ..result = (
        text: null,
        failure: const InputScanFailure('Clipboard kosong.'),
      );
    final controller = ShareLinkController(
      clipboardRepository: repository,
      prepareScanPreview: prepare,
      exampleUrl: 'https://shared.example.com',
    );
    addTearDown(controller.dispose);
    controller.useExample();
    expect((await controller.paste())!.failure!.message, 'Clipboard kosong.');
    expect(controller.url, 'https://shared.example.com');
    expect(controller.usingExample, isTrue);
  });

  test(
    'late paste is ignored after the share controller is disposed',
    () async {
      final repository = FakeClipboardRepository()
        ..pending = Completer<ClipboardResult>();
      final controller = ShareLinkController(
        clipboardRepository: repository,
        prepareScanPreview: prepare,
        exampleUrl: 'https://shared.example.com',
      );
      final pending = controller.paste();
      controller.dispose();
      repository.pending!.complete((
        text: 'https://late.example.com',
        failure: null,
      ));
      expect(await pending, isNull);
    },
  );

  test('QR controller delegates the injected example to domain validation', () {
    const valid = ScanQrController(
      prepareScanPreview: prepare,
      exampleUrl: 'https://qr.example.com',
    );
    expect(
      valid.prepareExamplePreview().preview!.urls.single.host,
      'qr.example.com',
    );
    const invalid = ScanQrController(
      prepareScanPreview: prepare,
      exampleUrl: 'invalid',
    );
    expect(invalid.prepareExamplePreview().preview, isNull);
    expect(invalid.prepareExamplePreview().failure, isNotNull);
  });
}
