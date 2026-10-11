import '../entities/prediction_report.dart';

/// Write access for corrections submitted against a prediction.
abstract class PredictionReportRepository {
  List<String> getCategories();

  bool submit(PredictionReport report);
}
