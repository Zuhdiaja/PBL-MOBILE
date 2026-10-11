import '../entities/user_account.dart';

/// Read access to the signed-in account's profile and preferences.
abstract class AccountRepository {
  /// Counts shown above the profile actions.
  AccountStats readStats();

  /// Whether status report notifications are turned on.
  bool readReportNotificationsEnabled();

  /// Stores the notification preference.
  void writeReportNotificationsEnabled(bool enabled);
}
