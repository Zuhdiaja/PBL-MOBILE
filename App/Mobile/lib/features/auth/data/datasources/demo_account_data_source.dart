import 'account_data_source.dart';

/// Holds the profile numbers and preferences for the current prototype user.
class DemoAccountDataSource implements AccountDataSource {
  static const totalScans = 8;
  static const submittedReports = 3;
  static const pendingReports = 1;

  bool _reportNotificationsEnabled = true;

  @override
  int readTotalScans() => totalScans;

  @override
  int readSubmittedReports() => submittedReports;

  @override
  int readPendingReports() => pendingReports;

  @override
  Future<bool> readReportNotificationsEnabled() async =>
      _reportNotificationsEnabled;

  @override
  Future<void> writeReportNotificationsEnabled(bool enabled) async =>
      _reportNotificationsEnabled = enabled;
}
