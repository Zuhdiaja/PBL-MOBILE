import '../entities/scan_result.dart';

/// Counts how many results are safe and how many need attention.
class SummarizeScanResults {
  const SummarizeScanResults();

  ScanResultSummary call(Iterable<ScanResult> results) {
    var safeCount = 0;
    for (final result in results) {
      if (result.isSafe) safeCount++;
    }
    final totalCount = results.length;
    return ScanResultSummary(
      totalCount: totalCount,
      safeCount: safeCount,
      attentionCount: totalCount - safeCount,
    );
  }
}
