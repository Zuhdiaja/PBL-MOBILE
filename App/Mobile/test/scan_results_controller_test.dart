import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/scan_results/data/datasources/demo_prediction_report_data_source.dart';
import 'package:pbl_semester5/features/scan_results/data/repositories/prediction_report_repository_impl.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/prediction_report.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/scan_result.dart';
import 'package:pbl_semester5/features/scan_results/domain/repositories/scan_results_repository.dart';
import 'package:pbl_semester5/features/scan_results/domain/usecases/submit_prediction_report.dart';
import 'package:pbl_semester5/features/scan_results/domain/usecases/summarize_scan_results.dart';
import 'package:pbl_semester5/features/scan_results/presentation/controllers/report_prediction_controller.dart';
import 'package:pbl_semester5/features/scan_results/presentation/controllers/scan_results_controller.dart';

class _FakeScanResultsRepository implements ScanResultsRepository {
  _FakeScanResultsRepository(this._results);

  final List<ScanResult> _results;

  @override
  List<ScanResult> getScanResults() => _results;

  @override
  ScanResult findById(String id) =>
      _results.firstWhere((result) => result.id == id);
}

ScanResult _result(String id, {required bool isSafe}) => ScanResult(
  id: id,
  url: '$id.example.test',
  category: isSafe ? 'Benign' : 'Phishing',
  riskLevel: isSafe ? 'Low Risk' : 'High Risk',
  confidence: isSafe ? 95 : 90,
  isSafe: isSafe,
  scanTime: '18 Sep 2026, 09:12 WIB',
  modelName: 'Model Demo',
  method: 'Simulasi klasifikasi URL',
);

void main() {
  group('ScanResultsController', () {
    test('loads results and derives the summary', () {
      final controller = ScanResultsController(
        repository: _FakeScanResultsRepository([
          _result('0', isSafe: true),
          _result('1', isSafe: false),
        ]),
        summarizeScanResults: const SummarizeScanResults(),
      );
      addTearDown(controller.dispose);

      controller.load();

      expect(controller.results.length, 2);
      expect(controller.summary.totalCount, 2);
      expect(controller.summary.safeCount, 1);
      expect(controller.summary.attentionCount, 1);
    });

    test('notifies listeners when results load', () {
      final controller = ScanResultsController(
        repository: _FakeScanResultsRepository([_result('0', isSafe: true)]),
        summarizeScanResults: const SummarizeScanResults(),
      );
      addTearDown(controller.dispose);

      var notified = 0;
      controller.addListener(() => notified++);

      controller.load();

      expect(notified, 1);
    });

    test('starts empty before the first load', () {
      final controller = ScanResultsController(
        repository: _FakeScanResultsRepository(const []),
        summarizeScanResults: const SummarizeScanResults(),
      );
      addTearDown(controller.dispose);

      expect(controller.results, isEmpty);
      expect(controller.summary.totalCount, 0);
    });
  });

  group('ReportPredictionController', () {
    ReportPredictionController build({bool accepts = true, String url = '0'}) {
      return ReportPredictionController(
        result: _result(url, isSafe: false),
        repository: PredictionReportRepositoryImpl(
          DemoPredictionReportDataSource(delivers: accepts),
        ),
        submitPredictionReport: const SubmitPredictionReport(),
      );
    }

    test('defaults to a false positive with no category', () {
      final controller = build();
      addTearDown(controller.dispose);

      expect(controller.type, ReportType.falsePositive);
      expect(controller.category, isEmpty);
    });

    test('changing the type notifies listeners', () {
      final controller = build();
      addTearDown(controller.dispose);

      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectType(ReportType.falseNegative);

      expect(controller.type, ReportType.falseNegative);
      expect(notified, 1);
    });

    test('selecting the same type does not notify again', () {
      final controller = build();
      addTearDown(controller.dispose);

      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectType(ReportType.falsePositive);

      expect(notified, 0);
    });

    test('submitting without a category returns a message', () {
      final controller = build();
      addTearDown(controller.dispose);

      expect(controller.submit(), contains('Pilih kategori'));
    });

    test('submitting with a category succeeds', () {
      final controller = build();
      addTearDown(controller.dispose);

      controller.selectCategory('Malware');
      controller.notes.text = 'TAUTAN PROGRAM BERBAHAYA';

      expect(controller.submit(), isNull);
    });

    test('clearing the category resets it', () {
      final controller = build();
      addTearDown(controller.dispose);

      controller.selectCategory('Malware');
      controller.selectCategory(null);

      expect(controller.category, isEmpty);
    });

    test('exposes the categories offered by the repository', () {
      final controller = build();
      addTearDown(controller.dispose);

      expect(controller.categories, contains('Phishing'));
    });
  });
}
