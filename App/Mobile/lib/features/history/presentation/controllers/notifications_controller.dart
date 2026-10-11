import 'package:flutter/foundation.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

/// State for the notification list and the read marks kept in memory.
class NotificationsController extends ChangeNotifier {
  NotificationsController(this.repository);

  final NotificationsRepository repository;

  List<AppNotification> _notifications = const [];
  final _readIds = <String>{};

  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where(isUnread).length;

  bool isUnread(AppNotification item) =>
      item.unread && !_readIds.contains(item.id);

  void load() {
    _notifications = repository.getNotifications();
    notifyListeners();
  }

  void markAllRead() {
    for (final item in _notifications) {
      if (item.unread) _readIds.add(item.id);
    }
    notifyListeners();
  }
}
