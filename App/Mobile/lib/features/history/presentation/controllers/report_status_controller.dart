import '../../../../presentation/load_controller.dart';

import '../../domain/entities/history_failure.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../../domain/usecases/build_report_timeline.dart';

/// State for the list of reports the user has submitted.
class ReportStatusController extends LoadController {
  ReportStatusController({
    required this.repository,
    required this.buildReportTimeline,
    this.isSimulated = true,
  });

  final ReportStatusRepository repository;
  final BuildReportTimeline buildReportTimeline;

  /// True while the list comes from example data instead of the API.
  final bool isSimulated;

  List<ReportStatus> _reports = const [];

  List<ReportStatus> get reports => _reports;

  @override
  Future<void> load() {
    return loadValue(
      repository.getReports,
      (value) => _reports = value,
      describeError: (error) => error is HistoryFailure ? error.message : null,
    );
  }
}
