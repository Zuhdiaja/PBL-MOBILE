import '../../../../data/scan_result.dart';
import '../../domain/entities/recent_scan.dart';

class RecentScanModel {
  const RecentScanModel({required this.id, required this.item});

  final String id;
  final ScanResultItem item;

  RecentScan toEntity() => RecentScan(
    id: id,
    url: item.url,
    category: item.category,
    isSafe: item.isSafe,
    scanTime: item.scanTime,
  );
}
