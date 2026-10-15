import 'dart:async';

import '../entities/report_status.dart';

/// Read access to the reports the user has submitted.
abstract class ReportStatusRepository {
  FutureOr<List<ReportStatus>> getReports();
}
