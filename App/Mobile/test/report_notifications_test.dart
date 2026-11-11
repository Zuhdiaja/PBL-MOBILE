import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/history/data/repositories/report_notifications_repository.dart';
import 'package:pbl_semester5/features/history/domain/entities/app_notification.dart';
import 'package:pbl_semester5/features/history/domain/entities/report_status.dart';
import 'package:pbl_semester5/features/history/domain/repositories/report_status_repository.dart';
import 'package:pbl_semester5/features/history/domain/usecases/build_notifications_from_reports.dart';

class _FakeReportStatusRepository implements ReportStatusRepository {
  _FakeReportStatusRepository(this._reports);

  final List<ReportStatus> _reports;
  var reads = 0;

  @override
  Future<List<ReportStatus>> getReports() async {
    reads++;
    return _reports;
  }
}

ReportStatus _report({
  String id = '1',
  String url = 'https://contoh.example.test/login',
  ReportStage stage = ReportStage.submitted,
  DateTime? submittedAt,
}) => ReportStatus(
  id: id,
  url: url,
  reportedCategory: 'Phishing',
  type: 'False Negative',
  stage: stage,
  submittedTime: '11 Nov 2026, 16:05 WIB',
  submittedAt: submittedAt ?? DateTime.utc(2026, 11, 11, 9, 5),
);

void main() {
  group('BuildNotificationsFromReports', () {
    const build = BuildNotificationsFromReports();

    test('creates one notification per report with a stable id', () {
      final items = build([
        _report(id: '7'),
        _report(id: '8', stage: ReportStage.review),
      ], now: DateTime.utc(2026, 11, 11, 10));

      expect(items.length, 2);
      expect(items.map((item) => item.id), ['report-7', 'report-8']);
      expect(
        items.every((item) => item.kind == NotificationKind.report),
        isTrue,
      );
    });

    test('describes every report stage', () {
      final items = build([
        _report(id: '1', stage: ReportStage.submitted),
        _report(id: '2', stage: ReportStage.review),
        _report(id: '3', stage: ReportStage.completed),
        _report(id: '4', stage: ReportStage.rejected),
      ], now: DateTime.utc(2026, 11, 11, 10));

      expect(items.map((item) => item.title), [
        'Laporan diterima',
        'Laporan sedang ditinjau',
        'Laporan selesai ditinjau',
        'Laporan ditolak',
      ]);
      expect(items.first.body, contains('contoh.example.test'));
    });

    test('keeps only the settled stages unread', () {
      final items = build([
        _report(id: '1', stage: ReportStage.submitted),
        _report(id: '2', stage: ReportStage.review),
      ], now: DateTime.utc(2026, 11, 11, 10));

      expect(items.first.unread, isFalse);
      expect(items.last.unread, isTrue);
    });

    test('groups reports submitted today apart from older ones', () {
      final items = build([
        _report(id: '1', submittedAt: DateTime.utc(2026, 11, 11, 1)),
        _report(id: '2', submittedAt: DateTime.utc(2026, 11, 10, 1)),
      ], now: DateTime.utc(2026, 11, 11, 10));

      expect(items.first.group, 'Hari ini');
      expect(items.last.group, 'Sebelumnya');
    });

    test('uses the WIB day when deciding what counts as today', () {
      // 18:00 UTC is already 01:00 WIB on the next day.
      final items = build([
        _report(id: '1', submittedAt: DateTime.utc(2026, 11, 10, 18)),
      ], now: DateTime.utc(2026, 11, 10, 19));

      expect(items.single.group, 'Hari ini');
    });
  });

  group('ReportNotificationsRepository', () {
    test('returns nothing when the preference is off', () async {
      final reports = _FakeReportStatusRepository([_report()]);
      final repository = ReportNotificationsRepository(
        reports: reports,
        readEnabled: () async => false,
        buildNotifications: const BuildNotificationsFromReports(),
      );

      expect(await repository.getNotifications(), isEmpty);
      expect(reports.reads, 0);
    });

    test('builds notifications from the reports when enabled', () async {
      final repository = ReportNotificationsRepository(
        reports: _FakeReportStatusRepository([
          _report(id: '5', stage: ReportStage.completed),
        ]),
        readEnabled: () async => true,
        buildNotifications: const BuildNotificationsFromReports(),
      );

      final items = await repository.getNotifications();

      expect(items.single.id, 'report-5');
      expect(items.single.title, 'Laporan selesai ditinjau');
    });
  });
}
