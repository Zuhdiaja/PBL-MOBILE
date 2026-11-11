import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../../domain/usecases/build_notifications_from_reports.dart';

/// Builds notifications from the reports the signed-in user submitted.
///
/// The preference is read on every load so turning notifications off hides
/// them immediately, and the empty list is a real answer rather than an error.
class ReportNotificationsRepository implements NotificationsRepository {
  const ReportNotificationsRepository({
    required this.reports,
    required this.readEnabled,
    required this.buildNotifications,
  });

  final ReportStatusRepository reports;
  final Future<bool> Function() readEnabled;
  final BuildNotificationsFromReports buildNotifications;

  @override
  Future<List<AppNotification>> getNotifications() async {
    if (!await readEnabled()) return const [];
    return buildNotifications(await reports.getReports());
  }
}
