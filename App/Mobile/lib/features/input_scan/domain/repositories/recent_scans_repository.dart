import 'dart:async';

import '../entities/recent_scan.dart';

abstract class RecentScansRepository {
  FutureOr<List<RecentScan>> getRecentScans();
}
