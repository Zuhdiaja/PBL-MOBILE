import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/history/domain/entities/app_notification.dart';
import 'package:pbl_semester5/features/history/domain/entities/history_entry.dart';
import 'package:pbl_semester5/features/history/domain/entities/history_page.dart';
import 'package:pbl_semester5/features/history/domain/entities/report_status.dart';
import 'package:pbl_semester5/features/history/domain/repositories/history_repository.dart';
import 'package:pbl_semester5/features/history/domain/repositories/notification_read_store.dart';
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

class _MutableHistoryRepository implements HistoryRepository {
  _MutableHistoryRepository(this.entries);

  List<HistoryEntry> entries;
  Object? error;

  @override
  List<HistoryEntry> getEntries() {
    final failure = error;
    if (failure != null) throw failure;
    return entries;
  }
}

class _MemoryReadStore implements NotificationReadStore {
  Set<String> ids = {};

  @override
  Future<Set<String>> read() async => ids;

  @override
  Future<void> write(Set<String> value) async => ids = value;
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

    testWidgets('debounces searches and ignores a stale page response', (
      tester,
    ) async {
      final older = _entry('older', category: 'Legitimate', isSafe: true);
      final newer = _entry('newer', category: 'Phishing', isSafe: false);
      final stale = Completer<HistoryPage<HistoryEntry>>();
      final requests = <(int, HistoryQuery)>[];
      final controller = HistoryController(
        repository: _FakeHistoryRepository([]),
        filterHistoryEntries: const FilterHistoryEntries(),
        searchPage: (page, query) async {
          requests.add((page, query));
          if (query.search.isEmpty) {
            return (items: [newer], page: 1, pageCount: 2, total: 101);
          }
          if (query.search == 'newer') return stale.future;
          return (items: [older], page: 1, pageCount: 1, total: 1);
        },
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.visibleEntries, [newer]);
      controller.setQuery('newer');
      await tester.pump(const Duration(milliseconds: 300));

      controller.setQuery('old');
      await tester.pump(const Duration(milliseconds: 100));
      controller.setQuery('older');
      await tester.pump(const Duration(milliseconds: 300));
      expect(requests.map((request) => request.$2.search), [
        '',
        'newer',
        'older',
      ]);
      expect(controller.visibleEntries, [older]);
      expect(controller.resultCount, 1);

      stale.complete((items: [newer], page: 1, pageCount: 1, total: 1));
      await tester.pump();
      expect(controller.visibleEntries, [older]);
      expect(controller.isLoading, isFalse);
      expect(controller.hasMore, isFalse);
      expect(controller.filters, contains('Legitimate'));
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

    test('read marks survive a new controller for the same account', () async {
      final store = _MemoryReadStore();
      final first = NotificationsController(
        _FakeNotificationsRepository([
          _notification('0', unread: true),
          _notification('1', unread: true),
        ]),
        readStore: store,
      );
      addTearDown(first.dispose);
      await first.load();
      await first.markAllRead();
      expect(store.ids, {'0', '1'});

      final second = NotificationsController(
        _FakeNotificationsRepository([
          _notification('0', unread: true),
          _notification('1', unread: true),
        ]),
        readStore: store,
      );
      addTearDown(second.dispose);
      await second.load();

      expect(second.unreadCount, 0);
    });
  });

  group('silent refresh', () {
    test('updates the data without showing the loading state', () async {
      final repository = _MutableHistoryRepository([
        _entry('a', category: 'Aman', isSafe: true),
      ]);
      final controller = HistoryController(
        repository: repository,
        filterHistoryEntries: const FilterHistoryEntries(),
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.entries.length, 1);

      repository.entries = [
        _entry('a', category: 'Aman', isSafe: true),
        _entry('b', category: 'Phishing', isSafe: false),
      ];
      var loadingSeen = false;
      controller.addListener(() {
        if (controller.isLoading) loadingSeen = true;
      });

      await controller.refresh();

      expect(controller.entries.length, 2);
      expect(loadingSeen, isFalse);
      expect(controller.loadError, isNull);
    });

    test('keeps the previous data when the refresh fails', () async {
      final repository = _MutableHistoryRepository([
        _entry('a', category: 'Aman', isSafe: true),
      ]);
      final controller = HistoryController(
        repository: repository,
        filterHistoryEntries: const FilterHistoryEntries(),
      );
      addTearDown(controller.dispose);
      await controller.load();

      repository.error = StateError('offline');
      await controller.refresh();

      expect(controller.entries.length, 1);
      expect(controller.loadError, isNull);
      expect(controller.isLoading, isFalse);
    });
  });
}
