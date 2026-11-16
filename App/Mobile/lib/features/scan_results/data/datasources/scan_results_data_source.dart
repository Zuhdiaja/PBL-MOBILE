import '../../domain/entities/failed_scan.dart';
import '../models/scan_result_model.dart';

/// Source of the results shown on the results screen.
abstract class ScanResultsDataSource {
  List<ScanResultModel> readResults();

  ScanResultModel readResult(String id);

  /// URLs of the latest submission that could not be checked.
  List<FailedScan> readFailures();
}
