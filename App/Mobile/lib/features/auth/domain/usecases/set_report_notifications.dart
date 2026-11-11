import '../repositories/account_repository.dart';

/// Persists the status report notification preference.
class SetReportNotifications {
  const SetReportNotifications();

  Future<bool> call(bool enabled, AccountRepository repository) async {
    await repository.writeReportNotificationsEnabled(enabled);
    return repository.readReportNotificationsEnabled();
  }
}
