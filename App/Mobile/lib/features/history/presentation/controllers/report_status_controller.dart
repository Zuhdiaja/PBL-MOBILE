import '../../../../presentation/load_controller.dart';

import '../../domain/entities/report_status.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../../domain/usecases/build_report_timeline.dart';

/// State for the list of reports the user has submitted.
class ReportStatusController extends LoadController {
  ReportStatusController({
    required this.repository,
    required this.buildReportTimeline,
  });

  final ReportStatusRepository repository;
  final BuildReportTimeline buildReportTimeline;

  List<ReportStatus> _reports = const [];

  List<ReportStatus> get reports => _reports;

  @override
  Future<void> load() {
    return loadValue(repository.getReports, (value) => _reports = value);
  }
}
