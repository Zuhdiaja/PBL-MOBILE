import '../../../../data/scan_result.dart';
import '../../domain/entities/failed_scan.dart';
import '../models/scan_result_model.dart';
import 'scan_results_data_source.dart';

/// Adapter for the example results owned by the legacy results data.
///
/// The legacy model and its dummy list stay untouched so features that are
/// still migrating keep reading the same source.
class DemoScanResultsDataSource implements ScanResultsDataSource {
  @override
  List<ScanResultModel> readResults() => [
    for (var i = 0; i < demoScanResults.length; i++)
      ScanResultModel.fromLegacy('$i', demoScanResults[i]),
  ];

  @override
  ScanResultModel readResult(String id) =>
      ScanResultModel.fromLegacy(id, demoScanResults[int.parse(id)]);

  @override
  List<FailedScan> readFailures() => const [];
}
