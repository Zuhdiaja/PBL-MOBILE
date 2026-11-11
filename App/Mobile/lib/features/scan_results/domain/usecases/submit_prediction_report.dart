import '../entities/prediction_report.dart';
import '../repositories/prediction_report_repository.dart';

typedef SubmitReportResult = ({
  SubmittedPredictionReport? report,
  ScanResultsFailure? failure,
});

/// Validates a correction and hands it to the repository.
class SubmitPredictionReport {
  const SubmitPredictionReport();

  Future<SubmitReportResult> call(
    PredictionReport report,
    PredictionReportRepository repository,
  ) async {
    if (report.category.trim().isEmpty) {
      return (
        report: null,
        failure: const ScanResultsFailure(
          'Pilih kategori yang benar terlebih dahulu.',
        ),
      );
    }
    try {
      final submitted = await repository.submit(report);
      return (report: submitted, failure: null);
    } on ScanResultsFailure catch (failure) {
      return (report: null, failure: failure);
    }
  }
}
