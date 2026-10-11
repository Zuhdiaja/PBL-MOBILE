import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/data/scan_result.dart';
import 'package:pbl_semester5/features/scan_results/data/datasources/demo_prediction_report_data_source.dart';
import 'package:pbl_semester5/features/scan_results/data/datasources/scan_results_data_source.dart';
import 'package:pbl_semester5/features/scan_results/data/repositories/prediction_report_repository_impl.dart';
import 'package:pbl_semester5/features/scan_results/data/repositories/scan_results_repository_impl.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/prediction_report.dart';

void main() {
  group('ScanResultsRepositoryImpl', () {
    final repository = ScanResultsRepositoryImpl(ScanResultsDataSource());

    test('maps every legacy example result to an entity', () {
      final results = repository.getScanResults();

      expect(results.length, demoScanResults.length);
      expect(results.first.url, demoScanResults.first.url);
      expect(results.first.category, demoScanResults.first.category);
      expect(results.first.confidence, demoScanResults.first.confidence);
      expect(results.first.modelName, demoScanResults.first.modelName);
    });

    test('assigns stable ids that resolve back to the same result', () {
      final results = repository.getScanResults();

      for (var i = 0; i < results.length; i++) {
        expect(repository.findById(results[i].id).url, results[i].url);
      }
    });

    test('carries the safety flag without importing the legacy model', () {
      final results = repository.getScanResults();

      expect(results.first.isSafe, demoScanResults.first.isSafe);
    });

    test('returns an unmodifiable list', () {
      expect(
        () =>
            repository.getScanResults().add(repository.getScanResults().first),
        throwsUnsupportedError,
      );
    });
  });

  group('PredictionReportRepositoryImpl', () {
    test('offers the categories used by the report form', () {
      const repository = PredictionReportRepositoryImpl(
        DemoPredictionReportDataSource(),
      );

      expect(repository.getCategories(), [
        'Aman / Benign',
        'Phishing',
        'Malware',
        'Spam',
        'Lainnya',
      ]);
    });

    test('accepts a valid submission', () {
      const repository = PredictionReportRepositoryImpl(
        DemoPredictionReportDataSource(),
      );

      expect(
        repository.submit(
          const PredictionReport(
            url: 'contoh.example.test',
            type: ReportType.falseNegative,
            category: 'Malware',
          ),
        ),
        isTrue,
      );
    });

    test('reports a rejected write', () {
      final repository = PredictionReportRepositoryImpl(
        const DemoPredictionReportDataSource(delivers: false),
      );

      expect(
        repository.submit(
          const PredictionReport(
            url: 'contoh.example.test',
            type: ReportType.falsePositive,
            category: 'Phishing',
          ),
        ),
        isFalse,
      );
    });
  });
}
