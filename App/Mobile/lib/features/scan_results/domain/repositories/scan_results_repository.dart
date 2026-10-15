import 'dart:async';

import '../entities/scan_result.dart';

/// Read access to scan results owned by the results feature.
abstract class ScanResultsRepository {
  FutureOr<List<ScanResult>> getScanResults();

  FutureOr<ScanResult> findById(String id);
}
