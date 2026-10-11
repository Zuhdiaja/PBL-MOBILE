/// Kind of correction a user submits for a prediction.
enum ReportType { falsePositive, falseNegative }

/// Draft of a correction submitted for one prediction.
class PredictionReport {
  const PredictionReport({
    required this.url,
    required this.type,
    required this.category,
    this.notes = '',
  });

  final String url;
  final ReportType type;

  /// Category chosen by the user; empty means nothing was selected yet.
  final String category;
  final String notes;
}

/// Failure raised by the results and reporting rules.
class ScanResultsFailure {
  const ScanResultsFailure(this.message);

  final String message;
}
