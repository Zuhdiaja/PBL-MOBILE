/// One row of the scan history list.
///
/// Colors and icons are presentation concerns and stay outside the domain.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.url,
    required this.category,
    required this.confidence,
    required this.isSafe,
    required this.scanTime,
    required this.dayLabel,
    this.score,
    this.scoreKind,
  });

  final String id;
  final String url;
  final String category;

  /// Percentage shown for example results; real scans use [score] instead.
  final int confidence;
  final bool isSafe;
  final String scanTime;

  /// Grouping label for the list, e.g. '18 September 2026'.
  final String dayLabel;

  /// Model score for real scans, e.g. the `LinearSVC` margin.
  final double? score;
  final String? scoreKind;

  /// True when [score] is a margin, which is not a probability.
  bool get hasMarginScore => score != null && scoreKind == 'margin';

  /// Score formatted for the list, or null when there is none.
  String? get formattedScore => score?.toStringAsFixed(4);
}
