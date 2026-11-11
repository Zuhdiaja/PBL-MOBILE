/// Profile numbers and preferences the account screens read.
///
/// Two implementations exist: [DemoAccountDataSource] keeps everything in
/// memory, while PreferencesAccountDataSource stores the notification choice
/// on the device.
abstract class AccountDataSource {
  int readTotalScans();

  int readSubmittedReports();

  int readPendingReports();

  Future<bool> readReportNotificationsEnabled();

  Future<void> writeReportNotificationsEnabled(bool enabled);
}
