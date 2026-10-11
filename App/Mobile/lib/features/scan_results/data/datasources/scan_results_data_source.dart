import '../../../../data/scan_result.dart';
import '../models/scan_result_model.dart';

/// Adapter for the example results owned by the legacy results data.
///
/// The legacy model and its dummy list stay untouched so features that are
/// still migrating keep reading the same source.
class ScanResultsDataSource {
  List<ScanResultModel> readResults() => [
    for (var i = 0; i < demoScanResults.length; i++)
      ScanResultModel(id: '$i', item: demoScanResults[i]),
  ];

  ScanResultModel readResult(String id) =>
      ScanResultModel(id: id, item: demoScanResults[int.parse(id)]);
}
