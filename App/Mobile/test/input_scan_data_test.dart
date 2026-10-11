import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_semester5/data/scan_result.dart';
import 'package:pbl_semester5/features/input_scan/data/datasources/clipboard_data_source.dart';
import 'package:pbl_semester5/features/input_scan/data/datasources/demo_recent_scans_data_source.dart';
import 'package:pbl_semester5/features/input_scan/data/repositories/clipboard_repository_impl.dart';
import 'package:pbl_semester5/features/input_scan/data/repositories/recent_scans_repository_impl.dart';

class FakeClipboardDataSource implements ClipboardDataSource {
  FakeClipboardDataSource({this.text, this.error});

  final String? text;
  final Object? error;

  @override
  Future<String?> readText() async {
    if (error != null) throw error!;
    return text;
  }
}

void main() {
  test(
    'clipboard repository returns trimmed text without validating it',
    () async {
      final repository = ClipboardRepositoryImpl(
        FakeClipboardDataSource(text: '  belum-url  '),
      );
      final result = await repository.readText();
      expect(result.text, 'belum-url');
      expect(result.failure, isNull);
    },
  );

  test(
    'empty clipboard becomes a friendly failure without a replacement',
    () async {
      for (final text in [null, '', '  \n ']) {
        final result = await ClipboardRepositoryImpl(
          FakeClipboardDataSource(text: text),
        ).readText();
        expect(result.text, isNull);
        expect(
          result.failure!.message,
          'Belum ada teks untuk ditempel. Salin URL dahulu.',
        );
      }
    },
  );

  test(
    'platform exceptions are translated before reaching presentation',
    () async {
      final repository = ClipboardRepositoryImpl(
        FakeClipboardDataSource(error: PlatformException(code: 'denied')),
      );
      final result = await repository.readText();
      expect(result.text, isNull);
      expect(
        result.failure!.message,
        'Teks belum bisa ditempel. Masukkan URL manual.',
      );
    },
  );

  test(
    'recent summaries map to the same legacy detail without duplicating data',
    () {
      final source = DemoRecentScansDataSource();
      final summaries = RecentScansRepositoryImpl(source).getRecentScans();
      expect(summaries.length, demoScanResults.length);
      for (var i = 0; i < summaries.length; i++) {
        final summary = summaries[i];
        final original = demoScanResults[i];
        expect(source.resolveDetail(summary.id), same(original));
        expect(summary.url, original.url);
        expect(summary.category, original.category);
        expect(summary.isSafe, original.isSafe);
        expect(summary.scanTime, original.scanTime);
      }
      expect(() => summaries.clear(), throwsUnsupportedError);
    },
  );
}
