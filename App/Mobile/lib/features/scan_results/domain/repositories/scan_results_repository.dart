import '../entities/scan_result.dart';

/// Read access to scan results owned by the results feature.
abstract class ScanResultsRepository {
  List<ScanResult> getScanResults();

  ScanResult findById(String id);
}
