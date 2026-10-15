import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/history/domain/entities/app_notification.dart';
import 'package:pbl_semester5/features/history/domain/entities/history_entry.dart';
import 'package:pbl_semester5/features/history/domain/entities/report_status.dart';
import 'package:pbl_semester5/features/history/domain/repositories/history_repository.dart';
import 'package:pbl_semester5/features/history/domain/repositories/notifications_repository.dart';
import 'package:pbl_semester5/features/history/domain/repositories/report_status_repository.dart';
import 'package:pbl_semester5/features/history/domain/usecases/build_report_timeline.dart';
import 'package:pbl_semester5/features/history/domain/usecases/filter_history_entries.dart';
import 'package:pbl_semester5/features/history/domain/usecases/summarize_activity.dart';
import 'package:pbl_semester5/features/history/presentation/controllers/history_controller.dart';
import 'package:pbl_semester5/features/history/presentation/controllers/notifications_controller.dart';
import 'package:pbl_semester5/features/history/presentation/controllers/report_status_controller.dart';
import 'package:pbl_semester5/features/history/presentation/controllers/stats_controller.dart';

class _FakeHistoryRepository implements HistoryRepository {
  _FakeHistoryRepository(this._entries);

  final List<HistoryEntry> _entries;

  @override
  List<HistoryEntry> getEntries() => _entries;
}

class _FakeReportStatusRepository implements ReportStatusRepository {
  _FakeReportStatusRepository(this._reports);

  final List<ReportStatus> _reports;

  @override
  List<ReportStatus> getReports() => _reports;
}

class _FakeNotificationsRepository implements NotificationsRepository {
  _FakeNotificationsRepository(this._notifications);

  final List<AppNotification> _notifications;

  @override
  List<AppNotification> getNotifications() => _notifications;
}

HistoryEntry _entry(
  String id, {
  required String category,
  required bool isSafe,
}) => HistoryEntry(
  id: id,
  url: '$id.example.test',
  category: category,
  confidence: 90,
  isSafe: isSafe,
  scanTime: '18 Sep 2026, 09:12 WIB',
  dayLabel: '18 September 2026',
);

ReportStatus _report(String url, ReportStage stage) => ReportStatus(
  url: url,
  reportedCategory: 'Phishing',
  type: 'False Negative',
  stage: stage,
  submittedTime: '21 Sep 2026, 14:32 WIB',
);

AppNotification _notification(String id, {required bool unread}) =>
    AppNotification(
      id: id,
      title: 'Judul $id',
      body: 'Isi $id',
      time: '09:15',
      group: 'Hari ini',
      kind: NotificationKind.report,
      unread: unread,
    );

void main() {
  group('HistoryController', () {
    HistoryController build() => HistoryController(
      repository: _FakeHistoryRepository([
        _entry('0', category: 'Phishing', isSafe: false),
        _entry('1', category: 'Benign', isSafe: true),
      ]),
      filterHistoryEntries: const FilterHistoryEntries(),
    );

    test('starts on the neutral filter without entries', () {
      final controller = build();
      addTearDown(controller.dispose);

      expect(controller.filter, FilterHistoryEntries.allLabel);
      expect(controller.entries, isEmpty);
      expect(controller.visibleEntries, isEmpty);
    });

    test('loads the entries and their filter options', () async {
      final controller = build();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.entries.length, 2);
      expect(controller.filters, ['Semua', 'Phishing', 'Benign']);
      expect(controller.visibleEntries.length, 2);
    });

    test('narrowing the filter notifies and hides other categories', () async {
      final controller = build();
      addTearDown(controller.dispose);
      await controller.load();

      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectFilter('Phishing');

      expect(notified, 1);
      expect(controller.visibleEntries.map((item) => item.id), ['0']);
    });

    test('selecting the current filter does not notify again', () async {
      final controller = build();
      addTearDown(controller.dispose);
      await controller.load();

      var notified = 0;
      controller.addListener(() => notified++);

      controller.selectFilter(FilterHistoryEntries.allLabel);

      expect(notified, 0);
    });
  });

  group('StatsController', () {
    test('derives the summary from the entries and report count', () async {
      final controller = StatsController(
        historyRepository: _FakeHistoryRepository([
          _entry('0', category: 'Phishing', isSafe: false),
          _entry('1', category: 'Benign', isSafe: true),
        ]),
        reportStatusRepository: _FakeReportStatusRepository([
          _report('contoh.example.test', ReportStage.review),
        ]),
        summarizeActivity: const SummarizeActivity(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.summary.totalCount, 2);
      expect(controller.summary.safeCount, 1);
      expect(controller.summary.reportCount, 1);
      expect(controller.summary.safePercent, 50);
    });

    test('starts with an empty summary before the first load', () {
      final controller = StatsController(
        historyRepository: _FakeHistoryRepository(const []),
        reportStatusRepository: _FakeReportStatusRepository(const []),
        summarizeActivity: const SummarizeActivity(),
      );
      addTearDown(controller.dispose);

      expect(controller.summary.totalCount, 0);
    });
  });

  group('ReportStatusController', () {
    test('loads the reports and exposes the timeline builder', () async {
      final controller = ReportStatusController(
        repository: _FakeReportStatusRepository([
          _report('contoh.example.test', ReportStage.completed),
        ]),
        buildReportTimeline: const BuildReportTimeline(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.reports.length, 1);
      expect(
        controller.buildReportTimeline(controller.reports.single).activeIndex,
        2,
      );
    });
  });

  group('NotificationsController', () {
    NotificationsController build() => NotificationsController(
      _FakeNotificationsRepository([
        _notification('0', unread: true),
        _notification('1', unread: true),
        _notification('2', unread: false),
      ]),
    );

    test('counts only the unread notifications', () async {
      final controller = build();
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.notifications.length, 3);
      expect(controller.unreadCount, 2);
    });

    test('marking all as read clears every unread mark', () async {
      final controller = build();
      addTearDown(controller.dispose);
      await controller.load();

      var notified = 0;
      controller.addListener(() => notified++);

      controller.markAllRead();

      expect(notified, 1);
      expect(controller.unreadCount, 0);
      for (final item in controller.notifications) {
        expect(controller.isUnread(item), isFalse);
      }
    });
  });
}
