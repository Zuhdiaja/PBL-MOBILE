import 'dart:async';

import '../config/api_config.dart';
import '../data/scans_api.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/input_scan/domain/usecases/submit_scan.dart';
import '../features/scan_results/data/datasources/demo_prediction_report_data_source.dart';
import '../features/scan_results/data/datasources/demo_scan_results_data_source.dart';
import '../features/scan_results/data/datasources/remote_prediction_report_data_source.dart';
import '../features/scan_results/data/datasources/scan_results_data_source.dart';
import '../features/scan_results/data/datasources/session_scan_results_data_source.dart';
import '../features/scan_results/data/models/scan_result_model.dart';
import '../features/scan_results/data/repositories/prediction_report_repository_impl.dart';
import '../features/scan_results/data/repositories/scan_results_repository_impl.dart';
import '../features/scan_results/domain/entities/failed_scan.dart';
import '../features/scan_results/domain/entities/scan_result.dart';
import '../features/scan_results/domain/usecases/submit_prediction_report.dart';
import '../features/scan_results/domain/usecases/summarize_scan_results.dart';
import '../features/scan_results/presentation/controllers/report_prediction_controller.dart';
import '../features/scan_results/presentation/controllers/scan_results_controller.dart';

/// Composition root for the results, detail, and reporting feature.
///
/// Concrete and legacy data stay here so feature widgets never import them.
/// Passing a [tokenStore] connects corrections to the LinkGuard API and keeps
/// the results of the latest scan in memory; without one the feature keeps the
/// offline demo sources used by tests and previews.
class ScanResultsDependencies {
  ScanResultsDependencies({TokenStore? tokenStore, String? apiBaseUrl}) {
    _resultSource = tokenStore == null
        ? DemoScanResultsDataSource()
        : SessionScanResultsDataSource();
    _scansApi = tokenStore == null
        ? null
        : ScansApi(
            baseUrl: apiBaseUrl ?? defaultApiBaseUrl(),
            tokenStore: tokenStore,
          );
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

  late final ScanResultsDataSource _resultSource;
  late final ScansApi? _scansApi;
  late final ScanResultsRepositoryImpl _resultsRepository;
  FutureOr<ScanResult> loadResult(String id) => _resultsRepository.findById(id);

  late final ScanResultsController scanResults;
  late final PredictionReportRepositoryImpl _reports;

  /// Resolves a result for ids handed out by other features.
  ScanResult findResult(String id) => _resultSource.readResult(id).toEntity();

  /// Resolves a result, fetching it from the API when the session has not
  /// loaded that scan yet. History and the home list hand out stored scan ids.
  Future<ScanResult> resolveResult(String id) async {
    try {
      return findResult(id);
    } on StateError {
      final api = _scansApi;
      if (api == null) rethrow;
      final model = ScanResultModel.fromScan(await api.detail(id));
      final source = _resultSource;
      if (source is SessionScanResultsDataSource) source.remember([model]);
      return model.toEntity();
    }
  }

  /// Keeps the outcome of one submission and refreshes the results screen.
  ///
  /// Successful checks become results; the failed ones are kept aside so the
  /// screen can mark exactly which URLs still need another try.
  void storeSubmission(ScanSubmission submission) {
    final source = _resultSource;
    if (source is! SessionScanResultsDataSource) return;
    source.replace(
      results: [
        for (final attempt in submission.attempts)
          if (attempt.prediction != null)
            ScanResultModel.fromPrediction(attempt.prediction!),
      ],
      failures: [
        for (final attempt in submission.attempts)
          if (attempt.failure != null)
            FailedScan(url: attempt.url, message: attempt.failure!.message),
      ],
    );
    scanResults.load();
  }

  ReportPredictionController createReportController(ScanResult result) =>
      ReportPredictionController(
        result: result,
        repository: _reports,
        submitPredictionReport: const SubmitPredictionReport(),
      );

  void dispose() => scanResults.dispose();
}
