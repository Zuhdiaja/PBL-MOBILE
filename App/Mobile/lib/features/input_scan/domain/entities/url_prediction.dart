/// One URL the model classified.
///
/// [category] is the canonical class name (`Benign`, `Legitimate`, `Phishing`,
/// `Malware`, `Spam`, `Defacement`, `Exploit`, `Tidak diketahui`), not the raw
/// label returned by the API.
class UrlPrediction {
  const UrlPrediction({
    required this.scanId,
    required this.url,
    required this.category,
    required this.score,
    required this.scoreKind,
    this.modelRunId,
    this.createdAt,
  });

  /// Identifier the API assigned to this scan; quoted when reporting.
  final String scanId;
  final String url;
  final String category;

  /// `LinearSVC` margin for the chosen class. Not a probability: it can be
  /// negative and is not bounded by 0 and 1.
  final double score;

  /// How [score] should be read, e.g. `margin`.
  final String scoreKind;

  /// Version of the model that produced the prediction.
  final String? modelRunId;
  final DateTime? createdAt;

  /// True when [scoreKind] is a margin rather than a calibrated probability.
  bool get isMarginScore => scoreKind == 'margin';
}
