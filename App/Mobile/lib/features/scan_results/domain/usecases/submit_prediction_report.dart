import '../entities/prediction_report.dart';
import '../repositories/prediction_report_repository.dart';

typedef SubmitReportResult = ({bool submitted, ScanResultsFailure? failure});

/// Validates a correction before handing it to the repository.
class SubmitPredictionReport {
  const SubmitPredictionReport();

  SubmitReportResult call(
    PredictionReport report,
    PredictionReportRepository repository,
  ) {
    if (report.category.trim().isEmpty) {
      return (
        submitted: false,
        failure: const ScanResultsFailure(
          'Pilih kategori yang benar terlebih dahulu.',
        ),
      );
    }
    final submitted = repository.submit(report);
    return submitted
        ? (submitted: true, failure: null)
        : (
            submitted: false,
            failure: const ScanResultsFailure(
              'Laporan belum dapat dikirim. Coba lagi.',
            ),
          );
  }
}
