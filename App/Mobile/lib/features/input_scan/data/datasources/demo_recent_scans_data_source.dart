import '../../../../data/scan_result.dart';
import '../models/recent_scan_model.dart';

/// Adapter for the existing data owned by the results/history feature.
class DemoRecentScansDataSource {
  List<RecentScanModel> readScans() => [
    for (var i = 0; i < demoScanResults.length; i++)
      RecentScanModel(id: '$i', item: demoScanResults[i]),
  ];

  ScanResultItem resolveDetail(String id) => demoScanResults[int.parse(id)];
}
