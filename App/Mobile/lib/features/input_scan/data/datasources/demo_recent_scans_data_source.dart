import '../../../../data/scan_result.dart';
import '../models/recent_scan_model.dart';
import 'recent_scans_data_source.dart';

/// Adapter for the existing data owned by the results/history feature.
class DemoRecentScansDataSource implements RecentScansDataSource {
  @override
  List<RecentScanModel> readScans() => [
    for (var i = 0; i < demoScanResults.length; i++)
      RecentScanModel.fromLegacy('$i', demoScanResults[i]),
  ];

  ScanResultItem resolveDetail(String id) => demoScanResults[int.parse(id)];
}
