import '../../../../presentation/load_controller.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// State for the notification list and the read marks kept in memory.
class NotificationsController extends LoadController {
  NotificationsController(this.repository);

  final NotificationsRepository repository;

  List<AppNotification> _notifications = const [];
  final _readIds = <String>{};

  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where(isUnread).length;

  bool isUnread(AppNotification item) =>
      item.unread && !_readIds.contains(item.id);

  @override
  Future<void> load() {
    return loadValue(
      repository.getNotifications,
      (value) => _notifications = value,
    );
  }

  void markAllRead() {
    for (final item in _notifications) {
      if (item.unread) _readIds.add(item.id);
    }
    notifyListeners();
  }
}
