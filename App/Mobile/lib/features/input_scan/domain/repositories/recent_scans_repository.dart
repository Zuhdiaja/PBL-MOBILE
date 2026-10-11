import '../entities/recent_scan.dart';

abstract class RecentScansRepository {
  List<RecentScan> getRecentScans();
}
