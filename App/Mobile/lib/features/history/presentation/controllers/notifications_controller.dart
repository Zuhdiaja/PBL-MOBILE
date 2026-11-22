import '../../../../presentation/load_controller.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/history_failure.dart';
import '../../domain/repositories/notification_read_store.dart';
import '../../domain/repositories/notifications_repository.dart';

/// State for the notification list and the read marks kept for the account.
class NotificationsController extends LoadController {
  NotificationsController(
    this.repository, {
    this.isSimulated = true,
    this.readStore,
  });

  final NotificationsRepository repository;

  /// True while the list comes from example data instead of the API.
  final bool isSimulated;

  /// Null when the marks only live in memory, e.g. in previews and tests.
  final NotificationReadStore? readStore;

  List<AppNotification> _notifications = const [];
  final _readIds = <String>{};

  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where(isUnread).length;

  bool isUnread(AppNotification item) =>
      item.unread && !_readIds.contains(item.id);

  @override
  Future<void> load() {
    return loadValue(
      _read,
      (value) => _notifications = value,
      describeError: (error) => error is HistoryFailure ? error.message : null,
    );
  }

  Future<void> refresh() {
    return refreshValue(_read, (value) => _notifications = value);
  }

  Future<List<AppNotification>> _read() async {
    final items = await repository.getNotifications();
    final stored = await readStore?.read();
    _readIds
      ..clear()
      ..addAll(stored ?? const <String>{});
    return items;
  }

  Future<void> markAllRead() async {
    for (final item in _notifications) {
      if (item.unread) _readIds.add(item.id);
    }
    notifyListeners();
    await readStore?.write(_readIds);
  }
}
