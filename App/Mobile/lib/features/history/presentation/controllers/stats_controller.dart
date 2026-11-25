import '../../../../presentation/load_controller.dart';

import '../../domain/entities/activity_summary.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../../domain/usecases/summarize_activity.dart';

/// State for the activity figures on the statistics screen.
class StatsController extends LoadController {
  StatsController({
    required this.historyRepository,
    required this.reportStatusRepository,
    required this.summarizeActivity,
    this.isSimulated = true,
    this.readSummary,
  });

  final HistoryRepository historyRepository;
  final ReportStatusRepository reportStatusRepository;
  final SummarizeActivity summarizeActivity;
  final Future<ActivitySummary> Function()? readSummary;

  /// True while the scan figures come from example data.
  final bool isSimulated;

  ActivitySummary _summary = const ActivitySummary(
    totalCount: 0,
    safeCount: 0,
    unsafeCount: 0,
    phishingCount: 0,
    malwareCount: 0,
    reportCount: 0,
    safePercent: 0,
  );

  ActivitySummary get summary => _summary;

  @override
  Future<void> load() => loadValue(_read, (value) => _summary = value);

  Future<void> refresh() => refreshValue(_read, (value) => _summary = value);

  Future<ActivitySummary> _read() async {
    if (readSummary case final read?) return read();
    final entries = await historyRepository.getEntries();
    final reports = await reportStatusRepository.getReports();
    return summarizeActivity(entries: entries, reportCount: reports.length);
  }
}
