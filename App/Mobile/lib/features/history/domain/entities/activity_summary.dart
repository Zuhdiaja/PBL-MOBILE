/// Aggregate figures shown on the statistics screen.
class ActivitySummary {
  const ActivitySummary({
    required this.totalCount,
    required this.safeCount,
    required this.unsafeCount,
    required this.phishingCount,
    required this.malwareCount,
    required this.reportCount,
    required this.safePercent,
  });

  final int totalCount;
  final int safeCount;
  final int unsafeCount;
  final int phishingCount;
  final int malwareCount;
  final int reportCount;
  final int safePercent;
}
