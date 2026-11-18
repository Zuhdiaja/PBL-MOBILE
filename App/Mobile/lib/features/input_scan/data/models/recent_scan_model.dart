import '../../../../data/scan_result.dart';
import '../../../../data/scan_time.dart';
import '../../../../data/scans_api.dart';
import '../../domain/entities/recent_scan.dart';

class RecentScanModel {
  const RecentScanModel._({
    required this.id,
    required this.url,
    required this.category,
    required this.isSafe,
    required this.scanTime,
  });

  factory RecentScanModel.fromLegacy(String id, ScanResultItem item) =>
      RecentScanModel._(
        id: id,
        url: item.url,
        category: item.category,
        isSafe: item.isSafe,
        scanTime: item.scanTime,
      );

  factory RecentScanModel.fromScan(ScanRecord record) => RecentScanModel._(
    id: record.id,
    url: record.url,
    category: record.category,
    isSafe: record.isSafe,
    scanTime: ScanTime.stamp(record.createdAt),
  );

  final String id;
  final String url;
  final String category;
  final bool isSafe;
  final String scanTime;

  RecentScan toEntity() => RecentScan(
    id: id,
    url: url,
    category: category,
    isSafe: isSafe,
    scanTime: scanTime,
  );
}
