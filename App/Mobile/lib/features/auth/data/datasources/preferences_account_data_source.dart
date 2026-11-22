import 'package:shared_preferences/shared_preferences.dart';

import '../../../../data/report_counts_api.dart';
import '../../../../data/scans_api.dart';
import 'account_data_source.dart';

/// Keeps the account preferences on the device and reads the scan and report
/// counts from the API.
class PreferencesAccountDataSource implements AccountDataSource {
  const PreferencesAccountDataSource({this.scans, this.reportCounts});

  static const _notificationsKey = 'linkguard_report_notifications';

  /// Null when the app runs without a session, e.g. in previews.
  final ScansApi? scans;

  /// Null when the app runs without a session, e.g. in previews.
  final ReportCountsApi? reportCounts;

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
  Future<int> readSubmittedReports() async => (await _counts()).total;

  @override
  Future<int> readPendingReports() async => (await _counts()).pending;

  Future<ReportCounts> _counts() async {
    final api = reportCounts;
    if (api == null) return const ReportCounts.empty();
    try {
      return await api.summary();
    } on ReportCountsException {
      // A failed count must not break the profile screen.
      return const ReportCounts.empty();
    }
  }

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
