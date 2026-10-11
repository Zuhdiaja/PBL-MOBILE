import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/prediction_report.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/scan_result.dart';
import 'package:pbl_semester5/features/scan_results/domain/repositories/prediction_report_repository.dart';
import 'package:pbl_semester5/features/scan_results/domain/usecases/submit_prediction_report.dart';
import 'package:pbl_semester5/features/scan_results/domain/usecases/summarize_scan_results.dart';

ScanResult result({required bool isSafe}) => ScanResult(
  id: '0',
  url: 'contoh.example.test',
  category: isSafe ? 'Benign' : 'Phishing',
  riskLevel: isSafe ? 'Low Risk' : 'High Risk',
  confidence: isSafe ? 98 : 96,
  isSafe: isSafe,
  scanTime: '18 Sep 2026, 09:12 WIB',
  modelName: 'Model Demo',
  method: 'Simulasi klasifikasi URL',
);

class _FakeReportRepository implements PredictionReportRepository {
  _FakeReportRepository({this.accepts = true});

  final bool accepts;
  final submitted = <PredictionReport>[];

  @override
  List<String> getCategories() => const ['Phishing', 'Spam'];

  @override
  bool submit(PredictionReport report) {
    submitted.add(report);
    return accepts;
  }
}

void main() {
  group('SummarizeScanResults', () {
    const summarize = SummarizeScanResults();

    test('splits results into safe and needing attention', () {
      final summary = summarize([
        result(isSafe: true),
        result(isSafe: false),
        result(isSafe: false),
      ]);

      expect(summary.totalCount, 3);
      expect(summary.safeCount, 1);
      expect(summary.attentionCount, 2);
    });

    test('handles an empty list', () {
      final summary = summarize(const <ScanResult>[]);

      expect(summary.totalCount, 0);
      expect(summary.safeCount, 0);
      expect(summary.attentionCount, 0);
    });
  });

  group('ScanResult defaults', () {
    test('unsafe result falls back to a warning recommendation', () {
      final value = result(isSafe: false);

      expect(value.resolvedRecommendation, contains('PERINGATAN'));
      expect(value.resolvedIndicators, isNotEmpty);
    });

    test('safe result keeps a cautionary recommendation', () {
      final value = result(isSafe: true);

      expect(value.resolvedRecommendation, contains('aman'));
    });

    test('provided values win over the defaults', () {
      final value = ScanResult(
        id: '1',
        url: 'lain.example.test',
        category: 'Spam',
        riskLevel: 'Medium Risk',
        confidence: 70,
        isSafe: false,
        scanTime: '18 Sep 2026, 09:12 WIB',
        modelName: 'Model Demo',
        method: 'Simulasi klasifikasi URL',
        recommendation: 'Rekomendasi khusus.',
        indicators: const ['Indikator khusus'],
      );

      expect(value.resolvedRecommendation, 'Rekomendasi khusus.');
      expect(value.resolvedIndicators, const ['Indikator khusus']);
    });
  });

  group('SubmitPredictionReport', () {
    const submitReport = SubmitPredictionReport();

    test('rejects a report without a category', () {
      final repository = _FakeReportRepository();

      final outcome = submitReport(
        const PredictionReport(
          url: 'contoh.example.test',
          type: ReportType.falsePositive,
          category: '',
        ),
        repository,
      );

      expect(outcome.submitted, isFalse);
      expect(outcome.failure?.message, contains('Pilih kategori'));
      expect(repository.submitted, isEmpty);
    });

    test('treats whitespace as a missing category', () {
      final outcome = submitReport(
        const PredictionReport(
          url: 'contoh.example.test',
          type: ReportType.falsePositive,
          category: '   ',
        ),
        _FakeReportRepository(),
      );

      expect(outcome.submitted, isFalse);
    });

    test('passes the report through when a category is chosen', () {
      final repository = _FakeReportRepository();

      final outcome = submitReport(
        const PredictionReport(
          url: 'contoh.example.test',
          type: ReportType.falseNegative,
          category: 'Phishing',
          notes: 'Mengambil data login.',
        ),
        repository,
      );

      expect(outcome.submitted, isTrue);
      expect(outcome.failure, isNull);
      expect(repository.submitted.single.type, ReportType.falseNegative);
      expect(repository.submitted.single.notes, 'Mengambil data login.');
    });

    test('turns a rejected write into a user facing failure', () {
      final outcome = submitReport(
        const PredictionReport(
          url: 'contoh.example.test',
          type: ReportType.falsePositive,
          category: 'Phishing',
        ),
        _FakeReportRepository(accepts: false),
      );

      expect(outcome.submitted, isFalse);
      expect(outcome.failure?.message, isNotEmpty);
    });
  });
}
