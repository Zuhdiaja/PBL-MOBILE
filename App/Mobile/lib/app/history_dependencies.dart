import '../config/api_config.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/history/data/datasources/demo_history_data_source.dart';
import '../features/history/data/datasources/demo_notifications_data_source.dart';
import '../features/history/data/datasources/demo_report_status_data_source.dart';
import '../features/history/data/datasources/remote_report_status_data_source.dart';
import '../features/history/data/repositories/history_repository_impl.dart';
import '../features/history/data/repositories/notifications_repository_impl.dart';
import '../features/history/data/repositories/report_status_repository_impl.dart';
import '../features/history/domain/usecases/build_report_timeline.dart';
import '../features/history/domain/usecases/filter_history_entries.dart';
import '../features/history/domain/usecases/summarize_activity.dart';
import '../features/history/presentation/controllers/history_controller.dart';
import '../features/history/presentation/controllers/notifications_controller.dart';
import '../features/history/presentation/controllers/report_status_controller.dart';
import '../features/history/presentation/controllers/stats_controller.dart';

/// Composition root for the history and monitoring feature.
///
/// Concrete and legacy data stay here so feature widgets never import them.
/// Passing a [tokenStore] reads the user's own reports from the API; without
/// one the feature keeps the example data used by tests and previews.
class HistoryDependencies {
  HistoryDependencies({TokenStore? tokenStore, String? apiBaseUrl}) {
    final history = HistoryRepositoryImpl(DemoHistoryDataSource());
    final reports = ReportStatusRepositoryImpl(
      tokenStore == null
          ? DemoReportStatusDataSource()
          : RemoteReportStatusDataSource(
              baseUrl: apiBaseUrl ?? defaultApiBaseUrl(),
              tokenStore: tokenStore,
            ),
    );
    final notifications = NotificationsRepositoryImpl(
      DemoNotificationsDataSource(),
    );

    this.history = HistoryController(
      repository: history,
      filterHistoryEntries: const FilterHistoryEntries(),
    );
    stats = StatsController(
      historyRepository: history,
      reportStatusRepository: reports,
      summarizeActivity: const SummarizeActivity(),
    );
    reportStatus = ReportStatusController(
      repository: reports,
      buildReportTimeline: const BuildReportTimeline(),
      isSimulated: tokenStore == null,
    );
    this.notifications = NotificationsController(notifications);
  }

  late final HistoryController history;
  late final StatsController stats;
  late final ReportStatusController reportStatus;
  late final NotificationsController notifications;

  void dispose() {
    history.dispose();
    stats.dispose();
    reportStatus.dispose();
    notifications.dispose();
  }
}
