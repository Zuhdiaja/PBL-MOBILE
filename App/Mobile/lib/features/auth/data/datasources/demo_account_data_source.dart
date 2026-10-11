/// Holds the profile numbers and preferences for the current prototype user.
class DemoAccountDataSource {
  static const totalScans = 8;
  static const submittedReports = 3;
  static const pendingReports = 1;

  bool _reportNotificationsEnabled = true;

  int readTotalScans() => totalScans;

  int readSubmittedReports() => submittedReports;

  int readPendingReports() => pendingReports;

  bool readReportNotificationsEnabled() => _reportNotificationsEnabled;

  void writeReportNotificationsEnabled(bool enabled) =>
      _reportNotificationsEnabled = enabled;
}
