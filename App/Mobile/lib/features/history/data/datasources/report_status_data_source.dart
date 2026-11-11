import 'dart:async';

import '../models/report_status_model.dart';

/// Read access to the reports the signed-in user has submitted.
abstract class ReportStatusDataSource {
  FutureOr<List<ReportStatusModel>> readReports();
}
