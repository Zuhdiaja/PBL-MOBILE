import '../entities/activity_summary.dart';
import '../entities/history_entry.dart';

/// Counts the activity figures shown on the statistics screen.
class SummarizeActivity {
  const SummarizeActivity();

  ActivitySummary call({
    required Iterable<HistoryEntry> entries,
    required int reportCount,
  }) {
    final totalCount = entries.length;
    var safeCount = 0;
    var phishingCount = 0;
    var malwareCount = 0;
    for (final entry in entries) {
      if (entry.isSafe) safeCount++;
      if (entry.category == 'Phishing') phishingCount++;
      if (entry.category == 'Malware') malwareCount++;
    }
    return ActivitySummary(
      totalCount: totalCount,
      safeCount: safeCount,
      unsafeCount: totalCount - safeCount,
      phishingCount: phishingCount,
      malwareCount: malwareCount,
      reportCount: reportCount,
      safePercent: totalCount == 0 ? 0 : (safeCount * 100 / totalCount).round(),
    );
  }
}
