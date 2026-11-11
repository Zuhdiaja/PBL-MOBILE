import 'package:shared_preferences/shared_preferences.dart';

import 'account_data_source.dart';

/// Keeps the account preferences on the device.
///
/// The profile counters still come from the prototype figures until scan
/// storage exists; only the notification choice is persisted here.
class PreferencesAccountDataSource implements AccountDataSource {
  static const _notificationsKey = 'linkguard_report_notifications';

  @override
  int readTotalScans() => 0;

  @override
  int readSubmittedReports() => 0;

  @override
  int readPendingReports() => 0;

  @override
  Future<bool> readReportNotificationsEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_notificationsKey) ??
      true;

  @override
  Future<void> writeReportNotificationsEnabled(bool enabled) async =>
      (await SharedPreferences.getInstance()).setBool(
        _notificationsKey,
        enabled,
      );
}
