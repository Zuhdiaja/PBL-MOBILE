import '../repositories/account_repository.dart';

/// Persists the status report notification preference.
class SetReportNotifications {
  const SetReportNotifications();

  bool call(bool enabled, AccountRepository repository) {
    repository.writeReportNotificationsEnabled(enabled);
    return repository.readReportNotificationsEnabled();
  }
}
