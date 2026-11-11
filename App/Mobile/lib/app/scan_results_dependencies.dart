import 'dart:async';

import '../config/api_config.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/scan_results/data/datasources/demo_prediction_report_data_source.dart';
import '../features/scan_results/data/datasources/remote_prediction_report_data_source.dart';
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
/// Passing a [tokenStore] connects corrections to the LinkGuard API; without
/// one the feature keeps the offline demo source used by tests and previews.
class ScanResultsDependencies {
  ScanResultsDependencies({TokenStore? tokenStore, String? apiBaseUrl}) {
    _resultsRepository = ScanResultsRepositoryImpl(_resultSource);
    scanResults = ScanResultsController(
      repository: _resultsRepository,
      summarizeScanResults: const SummarizeScanResults(),
    );
    _reports = PredictionReportRepositoryImpl(
      tokenStore == null
          ? const DemoPredictionReportDataSource()
          : RemotePredictionReportDataSource(
              baseUrl: apiBaseUrl ?? defaultApiBaseUrl(),
              tokenStore: tokenStore,
            ),
    );
  }

  late final ScanResultsRepositoryImpl _resultsRepository;
  FutureOr<ScanResult> loadResult(String id) => _resultsRepository.findById(id);

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
