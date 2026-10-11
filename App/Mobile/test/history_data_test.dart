import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/data/demo_activity.dart';
import 'package:pbl_semester5/data/scan_result.dart';
import 'package:pbl_semester5/features/history/data/datasources/demo_history_data_source.dart';
import 'package:pbl_semester5/features/history/data/datasources/demo_notifications_data_source.dart';
import 'package:pbl_semester5/features/history/data/datasources/demo_report_status_data_source.dart';
import 'package:pbl_semester5/features/history/data/repositories/history_repository_impl.dart';
import 'package:pbl_semester5/features/history/data/repositories/notifications_repository_impl.dart';
import 'package:pbl_semester5/features/history/data/repositories/report_status_repository_impl.dart';
import 'package:pbl_semester5/features/history/domain/entities/app_notification.dart';
import 'package:pbl_semester5/features/history/domain/entities/report_status.dart';

void main() {
  group('HistoryRepositoryImpl', () {
    final repository = HistoryRepositoryImpl(DemoHistoryDataSource());

    test('maps every legacy example result to an entry', () {
      final entries = repository.getEntries();

      expect(entries.length, demoScanResults.length);
      expect(entries.first.url, demoScanResults.first.url);
      expect(entries.first.category, demoScanResults.first.category);
      expect(entries.first.confidence, demoScanResults.first.confidence);
      expect(entries.first.dayLabel, demoScanResults.first.dayLabel);
    });

    test('keeps ids aligned with the legacy order', () {
      final entries = repository.getEntries();

      for (var i = 0; i < entries.length; i++) {
        expect(entries[i].id, '$i');
        expect(entries[i].url, demoScanResults[i].url);
      }
    });

    test('returns an unmodifiable list', () {
      expect(
        () => repository.getEntries().add(repository.getEntries().first),
        throwsUnsupportedError,
      );
    });
  });

  group('ReportStatusRepositoryImpl', () {
    final repository = ReportStatusRepositoryImpl(DemoReportStatusDataSource());

    test('maps every legacy report', () {
      final reports = repository.getReports();

      expect(reports.length, demoReports.length);
      expect(reports.first.url, demoReports.first.url);
      expect(reports.first.type, demoReports.first.type);
      expect(reports.first.notes, demoReports.first.notes);
    });

    test('translates the legacy status text into a stage', () {
      final stages = {
        for (final report in repository.getReports()) report.url: report.stage,
      };

      expect(stages['docs.example.com'], ReportStage.completed);
      expect(stages['cashback-klaim.example.com'], ReportStage.review);
      expect(stages['track-paket-resi.example.com'], ReportStage.submitted);
    });
  });

  group('NotificationsRepositoryImpl', () {
    final repository = NotificationsRepositoryImpl(
      DemoNotificationsDataSource(),
    );

    test('maps every legacy notification', () {
      final notifications = repository.getNotifications();

      expect(notifications.length, demoNotifications.length);
      expect(notifications.first.title, demoNotifications.first.title);
      expect(notifications.first.unread, demoNotifications.first.unread);
    });

    test('translates the legacy icon into a notification kind', () {
      final kinds = {
        for (final item in repository.getNotifications()) item.title: item.kind,
      };

      expect(kinds['Laporan selesai ditinjau'], NotificationKind.report);
      expect(kinds['URL berbahaya terdeteksi'], NotificationKind.danger);
      expect(kinds['Scan selesai'], NotificationKind.scan);
    });
  });
}
