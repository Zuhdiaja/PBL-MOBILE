/// Remembers which notifications the account has already opened.
///
/// The marks outlive one app run, so reopening the app does not make every
/// notification look unread again.
abstract class NotificationReadStore {
  Future<Set<String>> read();

  Future<void> write(Set<String> ids);
}
