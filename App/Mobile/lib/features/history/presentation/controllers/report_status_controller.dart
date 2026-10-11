import 'package:flutter/foundation.dart';

import '../../domain/entities/report_status.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../../domain/usecases/build_report_timeline.dart';

/// State for the list of reports the user has submitted.
class ReportStatusController extends ChangeNotifier {
  ReportStatusController({
    required this.repository,
    required this.buildReportTimeline,
  });

  final ReportStatusRepository repository;
  final BuildReportTimeline buildReportTimeline;

  List<ReportStatus> _reports = const [];

  List<ReportStatus> get reports => _reports;

  void load() {
    _reports = repository.getReports();
    notifyListeners();
  }
}
