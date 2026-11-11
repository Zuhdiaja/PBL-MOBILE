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

/// Correction the API accepted and stored, identified by its report number.
class SubmittedPredictionReport {
  const SubmittedPredictionReport({required this.id, required this.status});

  /// Identifier assigned by the API; shown to the user as the report number.
  final int id;

  /// Status the server gave the report, `submitted` for a new correction.
  final String status;
}

/// Failure raised by the results and reporting rules.
class ScanResultsFailure implements Exception {
  const ScanResultsFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
