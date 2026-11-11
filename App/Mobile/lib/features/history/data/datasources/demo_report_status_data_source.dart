import '../../../../data/demo_activity.dart';
import '../models/report_status_model.dart';
import 'report_status_data_source.dart';

/// Adapter for the example reports owned by the legacy activity data.
class DemoReportStatusDataSource implements ReportStatusDataSource {
  @override
  List<ReportStatusModel> readReports() => [
    for (final report in demoReports) ReportStatusModel.fromLegacy(report),
  ];
}
