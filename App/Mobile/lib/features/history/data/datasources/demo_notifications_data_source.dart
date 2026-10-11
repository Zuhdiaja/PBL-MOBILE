import '../../../../data/demo_activity.dart';
import '../models/app_notification_model.dart';

/// Adapter for the example notifications owned by the legacy activity data.
class DemoNotificationsDataSource {
  List<AppNotificationModel> readNotifications() => [
    for (var i = 0; i < demoNotifications.length; i++)
      AppNotificationModel(id: '$i', item: demoNotifications[i]),
  ];
}
