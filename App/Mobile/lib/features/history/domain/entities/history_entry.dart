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
  });

  final String id;
  final String url;
  final String category;
  final int confidence;
  final bool isSafe;
  final String scanTime;

  /// Grouping label for the list, e.g. '18 September 2026'.
  final String dayLabel;
}
