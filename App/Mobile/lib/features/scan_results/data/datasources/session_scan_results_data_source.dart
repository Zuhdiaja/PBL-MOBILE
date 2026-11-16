import '../../domain/entities/failed_scan.dart';
import '../models/scan_result_model.dart';
import 'demo_scan_results_data_source.dart';
import 'scan_results_data_source.dart';

/// Holds the results of the latest submission for the current session.
///
/// The backend stores the scans already; until a history endpoint exists, the
/// app shows the run the user just made instead of example data. Ids handed out
/// by other features (the example "scan terbaru" list) still resolve through
/// the demo source so those screens keep working.
class SessionScanResultsDataSource implements ScanResultsDataSource {
  SessionScanResultsDataSource({DemoScanResultsDataSource? demo})
    : _demo = demo ?? DemoScanResultsDataSource();

  final DemoScanResultsDataSource _demo;
  List<ScanResultModel> _results = const [];
  List<FailedScan> _failures = const [];

  /// Replaces the session with the outcome of one submission.
  void replace({
    required List<ScanResultModel> results,
    required List<FailedScan> failures,
  }) {
    _results = List.unmodifiable(results);
    _failures = List.unmodifiable(failures);
  }

  @override
  List<ScanResultModel> readResults() => _results;

  @override
  ScanResultModel readResult(String id) {
    for (final model in _results) {
      if (model.id == id) return model;
    }
    return _demo.readResult(id);
  }

  @override
  List<FailedScan> readFailures() => _failures;
}
