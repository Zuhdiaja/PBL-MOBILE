import '../entities/prediction_report.dart';

/// Write access for corrections submitted against a prediction.
abstract class PredictionReportRepository {
  List<String> getCategories();

  /// Sends the correction and returns the stored record.
  ///
  /// Throws [ScanResultsFailure] when the correction cannot be delivered.
  Future<SubmittedPredictionReport> submit(PredictionReport report);
}
