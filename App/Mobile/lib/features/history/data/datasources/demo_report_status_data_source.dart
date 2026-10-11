import '../../../../data/demo_activity.dart';
import '../models/report_status_model.dart';

/// Adapter for the example reports owned by the legacy activity data.
class DemoReportStatusDataSource {
  List<ReportStatusModel> readReports() => [
    for (final report in demoReports) ReportStatusModel(report),
  ];
}
