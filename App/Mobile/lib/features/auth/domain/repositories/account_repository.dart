import 'dart:async';

import '../entities/user_account.dart';

/// Read access to the signed-in account's profile and preferences.
abstract class AccountRepository {
  /// Counts shown above the profile actions.
  FutureOr<AccountStats> readStats();

  /// Whether status report notifications are turned on.
  Future<bool> readReportNotificationsEnabled();

  /// Stores the notification preference.
  Future<void> writeReportNotificationsEnabled(bool enabled);
}
