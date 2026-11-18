import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/scans_api.dart';
import 'account_data_source.dart';

/// Keeps the account preferences on the device and reads the scan count from
/// the API.
///
/// The report counters stay at zero here: they belong to the reports feature,
/// which owns its own endpoint.
class PreferencesAccountDataSource implements AccountDataSource {
  const PreferencesAccountDataSource({this.scans});

  static const _notificationsKey = 'linkguard_report_notifications';

  /// Null when the app runs without a session, e.g. in previews.
  final ScansApi? scans;

  @override
  Future<int> readTotalScans() async {
    final api = scans;
    if (api == null) return 0;
    try {
      return (await api.summary()).total;
    } on ScansApiException {
      // A failed count must not break the profile screen.
      return 0;
    }
  }

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
