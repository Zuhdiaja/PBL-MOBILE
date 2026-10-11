import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/demo_notifications_data_source.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._dataSource);

  final DemoNotificationsDataSource _dataSource;

  @override
  List<AppNotification> getNotifications() => List.unmodifiable(
    _dataSource.readNotifications().map((model) => model.toEntity()),
  );
}
