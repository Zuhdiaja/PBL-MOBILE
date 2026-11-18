import '../../../../presentation/load_controller.dart';

import '../../domain/entities/failed_scan.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_results_repository.dart';
import '../../domain/usecases/summarize_scan_results.dart';

/// State for the list of results and the counts above it.
class ScanResultsController extends LoadController {
  ScanResultsController({
    required this.repository,
    required this.summarizeScanResults,
  });

  final ScanResultsRepository repository;
  final SummarizeScanResults summarizeScanResults;

  List<ScanResult> _results = const [];
  List<FailedScan> _failures = const [];
  ScanResultSummary _summary = const ScanResultSummary(
    totalCount: 0,
    safeCount: 0,
    attentionCount: 0,
  );

  List<ScanResult> get results => List.unmodifiable(_results);

  /// URLs of the latest submission that could not be checked.
  List<FailedScan> get failures => List.unmodifiable(_failures);

  ScanResultSummary get summary => _summary;

  @override
  Future<void> load() {
    return loadValue(
      () async {
        final results = await repository.getScanResults();
        final failures = await repository.getFailures();
        return (results: results, failures: failures);
      },
      (value) {
        _results = value.results;
        _summary = summarizeScanResults(value.results);
        _failures = value.failures;
      },
    );
  }
}
