import '../features/scan_results/data/datasources/demo_prediction_report_data_source.dart';
import '../features/scan_results/data/datasources/scan_results_data_source.dart';
import '../features/scan_results/data/repositories/prediction_report_repository_impl.dart';
import '../features/scan_results/data/repositories/scan_results_repository_impl.dart';
import '../features/scan_results/domain/entities/scan_result.dart';
import '../features/scan_results/domain/usecases/submit_prediction_report.dart';
import '../features/scan_results/domain/usecases/summarize_scan_results.dart';
import '../features/scan_results/presentation/controllers/report_prediction_controller.dart';
import '../features/scan_results/presentation/controllers/scan_results_controller.dart';

/// Composition root for the results, detail, and reporting feature.
///
/// Concrete and legacy data stay here so feature widgets never import them.
class ScanResultsDependencies {
  ScanResultsDependencies() {
    final results = ScanResultsRepositoryImpl(_resultSource);
    scanResults = ScanResultsController(
      repository: results,
      summarizeScanResults: const SummarizeScanResults(),
    );
    _reports = PredictionReportRepositoryImpl(DemoPredictionReportDataSource());
  }

  final _resultSource = ScanResultsDataSource();
  late final ScanResultsController scanResults;
  late final PredictionReportRepositoryImpl _reports;

  /// Resolves a result for ids handed out by other features.
  ScanResult findResult(String id) => _resultSource.readResult(id).toEntity();

  ReportPredictionController createReportController(ScanResult result) =>
      ReportPredictionController(
        result: result,
        repository: _reports,
        submitPredictionReport: const SubmitPredictionReport(),
      );

  void dispose() => scanResults.dispose();
}
