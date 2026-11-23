import 'account_data_source.dart';

/// Holds the profile numbers and preferences for the current prototype user.
class DemoAccountDataSource implements AccountDataSource {
  static const totalScans = 8;
  static const submittedReports = 3;
  static const pendingReports = 1;

  bool _reportNotificationsEnabled = true;

  @override
  Future<int> readTotalScans() async => totalScans;

  @override
  Future<int> readSubmittedReports() async => submittedReports;

  @override
  Future<int> readPendingReports() async => pendingReports;

  @override
  Future<bool> readReportNotificationsEnabled() async =>
      _reportNotificationsEnabled;

  @override
  Future<void> writeReportNotificationsEnabled(bool enabled) async =>
      _reportNotificationsEnabled = enabled;
}
