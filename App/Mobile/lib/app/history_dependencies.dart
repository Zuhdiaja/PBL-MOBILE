import '../config/api_config.dart';
import '../data/scans_api.dart';
import '../data/report_counts_api.dart';
import '../features/history/domain/entities/activity_summary.dart';
import '../features/scan_results/domain/entities/scan_category.dart';
import '../features/auth/data/datasources/token_store.dart';
import '../features/auth/domain/repositories/account_repository.dart';
import '../features/history/data/datasources/demo_history_data_source.dart';
import '../features/history/data/datasources/demo_notifications_data_source.dart';
import '../features/history/data/datasources/demo_report_status_data_source.dart';
import '../features/history/data/datasources/remote_history_data_source.dart';
import '../features/history/data/datasources/preferences_notification_read_store.dart';
import '../features/history/data/datasources/remote_report_status_data_source.dart';
import '../features/history/data/repositories/history_repository_impl.dart';
import '../features/history/data/repositories/notifications_repository_impl.dart';
import '../features/history/data/repositories/report_notifications_repository.dart';
import '../features/history/data/repositories/report_status_repository_impl.dart';
import '../features/history/domain/usecases/build_notifications_from_reports.dart';
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
  HistoryDependencies({
    TokenStore? tokenStore,
    String? apiBaseUrl,
    AccountRepository? accountRepository,
    String? accountId,
  }) {
    final base = apiBaseUrl ?? defaultApiBaseUrl();
    final scans = tokenStore == null
        ? null
        : ScansApi(baseUrl: base, tokenStore: tokenStore);
    final reportCounts = tokenStore == null
        ? null
        : ReportCountsApi(baseUrl: base, tokenStore: tokenStore);
    final remoteHistory = scans == null ? null : RemoteHistoryDataSource(scans);
    final remoteReports = tokenStore == null
        ? null
        : RemoteReportStatusDataSource(baseUrl: base, tokenStore: tokenStore);
    final history = HistoryRepositoryImpl(
      remoteHistory ?? DemoHistoryDataSource(),
    );
    final reports = ReportStatusRepositoryImpl(
      remoteReports ?? DemoReportStatusDataSource(),
    );
    final notifications = tokenStore == null || accountRepository == null
        ? NotificationsRepositoryImpl(DemoNotificationsDataSource())
        : ReportNotificationsRepository(
            reports: reports,
            readEnabled: accountRepository.readReportNotificationsEnabled,
            buildNotifications: const BuildNotificationsFromReports(),
          );

    this.history = HistoryController(
      repository: history,
      filterHistoryEntries: const FilterHistoryEntries(),
      searchPage: remoteHistory?.readPage,
      isSimulated: tokenStore == null,
    );
    stats = StatsController(
      historyRepository: history,
      reportStatusRepository: reports,
      summarizeActivity: const SummarizeActivity(),
      readSummary: scans == null || reportCounts == null
          ? null
          : () async {
              final week = await scans.summary(weekly: true);
              final counts = await reportCounts.summary();
              return ActivitySummary(
                totalCount: week.total,
                safeCount: week.safe,
                unsafeCount: week.unsafe,
                phishingCount: week.countOf(ScanCategory.phishing),
                malwareCount: week.countOf(ScanCategory.malware),
                reportCount: counts.total,
                safePercent: week.total == 0
                    ? 0
                    : (100 * week.safe / week.total).round(),
                weekly: week.weekly,
              );
            },
      isSimulated: tokenStore == null,
    );
    reportStatus = ReportStatusController(
      repository: reports,
      buildReportTimeline: const BuildReportTimeline(),
      readPage: remoteReports?.readPage,
      isSimulated: tokenStore == null,
    );
    this.notifications = NotificationsController(
      notifications,
      isSimulated: tokenStore == null || accountRepository == null,
      readStore: tokenStore == null || accountId == null
          ? null
          : PreferencesNotificationReadStore(accountId: accountId),
    );
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
