import '../entities/app_notification.dart';
import '../entities/report_status.dart';

/// Turns the status of the user's reports into in-app notifications.
class BuildNotificationsFromReports {
  const BuildNotificationsFromReports();

  /// [now] is injected so tests can pin the day used for grouping.
  List<AppNotification> call(List<ReportStatus> reports, {DateTime? now}) {
    final today = _wibDay(now ?? DateTime.now().toUtc());
    final items = <AppNotification>[];
    for (var i = 0; i < reports.length; i++) {
      final report = reports[i];
      final content = _contentFor(report);
      items.add(
        AppNotification(
          id: report.id.isNotEmpty ? 'report-${report.id}' : 'report-$i',
          title: content.title,
          body: content.body,
          time: report.submittedTime,
          group: _isToday(report, today) ? 'Hari ini' : 'Sebelumnya',
          kind: NotificationKind.report,
          unread: content.unread,
        ),
      );
    }
    return List.unmodifiable(items);
  }

  static ({String title, String body, bool unread}) _contentFor(
    ReportStatus report,
  ) {
    final host = _host(report.url);
    return switch (report.stage) {
      ReportStage.submitted => (
        title: 'Laporan diterima',
        body: 'Laporan untuk $host menunggu peninjauan admin.',
        unread: false,
      ),
      ReportStage.review => (
        title: 'Laporan sedang ditinjau',
        body: 'Laporan untuk $host sedang diperiksa admin.',
        unread: true,
      ),
      ReportStage.completed => (
        title: 'Laporan selesai ditinjau',
        body: 'Laporan untuk $host telah disetujui dan masuk ke dataset.',
        unread: true,
      ),
      ReportStage.rejected => (
        title: 'Laporan ditolak',
        body: 'Laporan untuk $host belum dapat diterima admin.',
        unread: true,
      ),
    };
  }

  static String _host(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.host.isNotEmpty ? uri.host : url;
  }

  static DateTime _wibDay(DateTime nowUtc) =>
      nowUtc.toUtc().add(const Duration(hours: 7));

  static bool _isToday(ReportStatus report, DateTime todayWib) {
    final submittedAt = report.submittedAt;
    if (submittedAt == null) return false;
    final wib = submittedAt.toUtc().add(const Duration(hours: 7));
    return wib.year == todayWib.year &&
        wib.month == todayWib.month &&
        wib.day == todayWib.day;
  }
}
