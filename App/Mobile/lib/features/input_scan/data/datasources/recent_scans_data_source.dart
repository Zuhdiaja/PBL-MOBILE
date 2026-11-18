import 'dart:async';

import '../models/recent_scan_model.dart';

/// Source of the "scan terbaru" list on the home screen.
abstract class RecentScansDataSource {
  FutureOr<List<RecentScanModel>> readScans();
}
