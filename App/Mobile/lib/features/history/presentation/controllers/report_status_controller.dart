import '../../domain/entities/history_page.dart';
import 'paged_history_controller.dart';

import '../../domain/entities/report_status.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../../domain/usecases/build_report_timeline.dart';

/// State for the list of reports the user has submitted.
class ReportStatusController extends PagedHistoryController<ReportStatus> {
  ReportStatusController({
    required this.repository,
    required this.buildReportTimeline,
    this.isSimulated = true,
    Future<HistoryPage<ReportStatus>> Function(int)? readPage,
  }) : super(repository.getReports, readPage, (item) => item.id);

  final ReportStatusRepository repository;
  final BuildReportTimeline buildReportTimeline;

  /// True while the list comes from example data instead of the API.
  final bool isSimulated;

  List<ReportStatus> get reports => items;
}
