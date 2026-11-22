/// Profile numbers and preferences the account screens read.
///
/// Two implementations exist: [DemoAccountDataSource] keeps everything in
/// memory, while PreferencesAccountDataSource stores the notification choice
/// on the device and reads the scan count from the API.
abstract class AccountDataSource {
  Future<int> readTotalScans();

  Future<int> readSubmittedReports();

  Future<int> readPendingReports();

  Future<bool> readReportNotificationsEnabled();

  Future<void> writeReportNotificationsEnabled(bool enabled);
}
