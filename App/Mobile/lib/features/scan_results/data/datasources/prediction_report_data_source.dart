import '../../domain/entities/prediction_report.dart';
import '../models/submitted_prediction_report_model.dart';

/// Delivery of corrections, implemented by a demo and a remote source.
abstract class PredictionReportDataSource {
  /// Correction categories offered by the form.
  List<String> readCategories();

  /// Stores the correction and returns the record the server created.
  ///
  /// Throws [ScanResultsFailure] with a message fit for the user when the
  /// correction cannot be delivered.
  Future<SubmittedPredictionReportModel> write(PredictionReport report);
}
