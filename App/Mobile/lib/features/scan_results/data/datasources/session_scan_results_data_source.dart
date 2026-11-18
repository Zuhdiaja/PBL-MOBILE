import '../../domain/entities/failed_scan.dart';
import '../models/scan_result_model.dart';
import 'demo_scan_results_data_source.dart';
import 'scan_results_data_source.dart';

/// Holds the results of the latest submission for the current session.
///
/// The backend stores the scans already; the app shows the run the user just
/// made plus whatever the history screen loaded. Numeric ids still resolve
/// through the demo source so previews keep working.
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

  /// Adds results loaded from elsewhere, e.g. the history list.
  void remember(Iterable<ScanResultModel> results) {
    final known = {for (final model in _results) model.id};
    final added = [
      for (final model in results)
        if (known.add(model.id)) model,
    ];
    if (added.isEmpty) return;
    _results = List.unmodifiable([..._results, ...added]);
  }

  @override
  List<ScanResultModel> readResults() => _results;

  @override
  ScanResultModel readResult(String id) {
    for (final model in _results) {
      if (model.id == id) return model;
    }
    // Example ids are small integers; anything else is a scan we do not hold.
    if (int.tryParse(id) != null) return _demo.readResult(id);
    throw StateError('Hasil pindai $id belum dimuat.');
  }

  @override
  List<FailedScan> readFailures() => _failures;
}
