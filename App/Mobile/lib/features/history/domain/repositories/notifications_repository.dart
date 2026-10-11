import '../entities/app_notification.dart';

/// Read access to the notification list.
abstract class NotificationsRepository {
  List<AppNotification> getNotifications();
}
