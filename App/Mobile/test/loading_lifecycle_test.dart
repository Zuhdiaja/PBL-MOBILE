import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/app/scan_results_dependencies.dart';
import 'package:pbl_semester5/features/auth/domain/entities/user_account.dart';
import 'package:pbl_semester5/features/auth/domain/repositories/account_repository.dart';
import 'package:pbl_semester5/features/auth/domain/usecases/load_account_stats.dart';
import 'package:pbl_semester5/features/auth/presentation/controllers/profile_controller.dart';
import 'package:pbl_semester5/features/auth/presentation/pages/profile_page.dart';
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
import 'package:pbl_semester5/features/history/presentation/pages/history_screen.dart';
import 'package:pbl_semester5/features/history/presentation/pages/notifications_screen.dart';
import 'package:pbl_semester5/features/history/presentation/pages/report_status_screen.dart';
import 'package:pbl_semester5/features/history/presentation/pages/stats_screen.dart';
import 'package:pbl_semester5/features/input_scan/domain/entities/recent_scan.dart';
import 'package:pbl_semester5/features/input_scan/domain/repositories/recent_scans_repository.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/prepare_scan_preview.dart';
import 'package:pbl_semester5/features/input_scan/presentation/controllers/home_controller.dart';
import 'package:pbl_semester5/features/input_scan/presentation/pages/home_screen.dart';
import 'package:pbl_semester5/features/input_scan/presentation/widgets/scan_preview_sheet.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/scan_result.dart';
import 'package:pbl_semester5/features/scan_results/domain/repositories/scan_results_repository.dart';
import 'package:pbl_semester5/features/scan_results/domain/usecases/summarize_scan_results.dart';
import 'package:pbl_semester5/features/scan_results/presentation/controllers/scan_detail_controller.dart';
import 'package:pbl_semester5/features/scan_results/presentation/controllers/scan_results_controller.dart';
import 'package:pbl_semester5/features/scan_results/presentation/pages/scan_detail_screen.dart';
import 'package:pbl_semester5/features/scan_results/presentation/pages/scan_result_screen.dart';
import 'package:pbl_semester5/presentation/load_controller.dart';
import 'package:pbl_semester5/theme/app_theme.dart';
import 'package:pbl_semester5/widgets/loading_states.dart';
import 'package:pbl_semester5/widgets/startup_gate.dart';

class Pending<T> {
  Completer<T> completer = Completer<T>();
  int reads = 0;
  Future<T> read() {
    reads++;
    return completer.future;
  }

  void fail() => completer.completeError(StateError('private internal error'));
  void retry() => completer = Completer<T>();
}

class HistorySource implements HistoryRepository {
  HistorySource(this.read);
  final FutureOr<List<HistoryEntry>> Function() read;
  @override
  FutureOr<List<HistoryEntry>> getEntries() => read();
}

class ReportSource implements ReportStatusRepository {
  ReportSource(this.read);
  final FutureOr<List<ReportStatus>> Function() read;
  @override
  FutureOr<List<ReportStatus>> getReports() => read();
}

class NotificationSource implements NotificationsRepository {
  NotificationSource(this.read);
  final FutureOr<List<AppNotification>> Function() read;
  @override
  FutureOr<List<AppNotification>> getNotifications() => read();
}

class RecentSource implements RecentScansRepository {
  RecentSource(this.read);
  final FutureOr<List<RecentScan>> Function() read;
  @override
  FutureOr<List<RecentScan>> getRecentScans() => read();
}

class ResultsSource implements ScanResultsRepository {
  ResultsSource(this.read);
  final FutureOr<List<ScanResult>> Function() read;
  @override
  FutureOr<List<ScanResult>> getScanResults() => read();
  @override
  Future<ScanResult> findById(String id) async => (await read()).first;
}

class AccountSource implements AccountRepository {
  AccountSource(this.read);
  final FutureOr<AccountStats> Function() read;
  @override
  FutureOr<AccountStats> readStats() => read();
  @override
  bool readReportNotificationsEnabled() => true;
  @override
  void writeReportNotificationsEnabled(bool enabled) {}
}

void noop() {}
Widget harness(Widget page, {bool reduced = false}) => MaterialApp(
  theme: linkGuardTheme(Brightness.light),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: Scaffold(body: SafeArea(child: page)),
);

void main() {
  for (final kind in [
    'home',
    'history',
    'stats',
    'profile',
    'results',
    'reports',
    'notifications',
  ]) {
    testWidgets(
      '$kind follows pending, failure, retry and successful empty data',
      (tester) async {
        late LoadController controller;
        late Widget page;
        late void Function() fail, retry, complete;
        switch (kind) {
          case 'home':
            final p = Pending<List<RecentScan>>();
            final c = HomeController(RecentSource(p.read));
            controller = c;
            page = HomeScreen(
              controller: c,
              onNotifications: noop,
              onRecentScan: (_) {},
              onScan: noop,
              onPaste: noop,
              onQr: noop,
              onShare: noop,
              onHistory: noop,
              onProfile: noop,
            );
            fail = p.fail;
            retry = p.retry;
            complete = () => p.completer.complete([]);
          case 'history':
            final p = Pending<List<HistoryEntry>>();
            final c = HistoryController(
              repository: HistorySource(p.read),
              filterHistoryEntries: const FilterHistoryEntries(),
            );
            controller = c;
            page = HistoryScreen(controller: c);
            fail = p.fail;
            retry = p.retry;
            complete = () => p.completer.complete([]);
          case 'stats':
            final p = Pending<List<HistoryEntry>>();
            final c = StatsController(
              historyRepository: HistorySource(p.read),
              reportStatusRepository: ReportSource(() => []),
              summarizeActivity: const SummarizeActivity(),
            );
            controller = c;
            page = StatsScreen(controller: c);
            fail = p.fail;
            retry = p.retry;
            complete = () => p.completer.complete([]);
          case 'profile':
            final p = Pending<AccountStats>();
            final c = ProfileController(
              repository: AccountSource(p.read),
              loadAccountStats: const LoadAccountStats(),
            );
            controller = c;
            page = ProfilePage(
              controller: c,
              account: const UserAccount(
                id: '1',
                name: 'Test User',
                email: 'test@example.test',
              ),
              onSettings: noop,
              onSignOut: noop,
              onReportStatus: noop,
              onNotifications: noop,
            );
            fail = p.fail;
            retry = p.retry;
            complete = () => p.completer.complete(const AccountStats.empty());
          case 'results':
            final p = Pending<List<ScanResult>>();
            final c = ScanResultsController(
              repository: ResultsSource(p.read),
              summarizeScanResults: const SummarizeScanResults(),
            );
            controller = c;
            page = ScanResultScreen(controller: c, onOpenDetail: (_) {});
            fail = p.fail;
            retry = p.retry;
            complete = () => p.completer.complete([]);
          case 'reports':
            final p = Pending<List<ReportStatus>>();
            final c = ReportStatusController(
              repository: ReportSource(p.read),
              buildReportTimeline: const BuildReportTimeline(),
            );
            controller = c;
            page = ReportStatusScreen(controller: c);
            fail = p.fail;
            retry = p.retry;
            complete = () => p.completer.complete([]);
          case 'notifications':
            final p = Pending<List<AppNotification>>();
            final c = NotificationsController(NotificationSource(p.read));
            controller = c;
            page = NotificationsScreen(controller: c);
            fail = p.fail;
            retry = p.retry;
            complete = () => p.completer.complete([]);
        }
        addTearDown(controller.dispose);
        await tester.pumpWidget(harness(page));
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(LoadingPulse), findsOneWidget);
        expect(controller.isLoading, isTrue);
        fail();
        await tester.pumpAndSettle();
        expect(find.text('Coba lagi'), findsOneWidget);
        expect(find.textContaining('private internal error'), findsNothing);
        retry();
        await tester.ensureVisible(find.text('Coba lagi'));
        await tester.tap(find.text('Coba lagi'));
        await tester.pump();
        expect(find.byType(LoadingPulse), findsOneWidget);
        complete();
        await tester.pumpAndSettle();
        expect(controller.hasLoaded, isTrue);
        expect(find.byType(LoadingPulse), findsNothing);
        expect(find.text('Coba lagi'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('detail waits for its repository and retries after failure', (
    tester,
  ) async {
    final deps = ScanResultsDependencies();
    addTearDown(deps.dispose);
    final result = deps.findResult('0');
    final p = Pending<ScanResult>();
    await tester.pumpWidget(
      harness(
        ScanDetailScreen(result: result, loadResult: p.read, onReport: (_) {}),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(LoadingPulse), findsOneWidget);
    expect(find.text(result.resolvedRecommendation), findsNothing);
    expect(find.text(result.url), findsOneWidget);
    p.fail();
    await tester.pumpAndSettle();
    p.retry();
    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    p.completer.complete(result);
    await tester.pumpAndSettle();
    expect(find.text('Saran keamanan'), findsOneWidget);
  });

  test(
    'loads are deduplicated and late completion cannot mutate disposed state',
    () async {
      final p = Pending<ScanResult>();
      final deps = ScanResultsDependencies();
      final result = deps.findResult('0');
      deps.dispose();
      final c = ScanDetailController(p.read);
      final one = c.load();
      final two = c.load();
      expect(identical(one, two), isTrue);
      expect(p.reads, 1);
      c.dispose();
      p.completer.complete(result);
      await one;
      expect(c.result, isNull);
    },
  );

  testWidgets(
    'splash waits beyond its entrance for initialization, then supports retry',
    (tester) async {
      final p = Pending<ScanResult>();
      final c = ScanDetailController(p.read);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        harness(StartupGate(controller: c, child: const Text('Ready'))),
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Ready'), findsNothing);
      p.fail();
      await tester.pumpAndSettle();
      expect(find.text('Coba lagi'), findsOneWidget);
      p.retry();
      await tester.ensureVisible(find.text('Coba lagi'));
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      final deps = ScanResultsDependencies();
      p.completer.complete(deps.findResult('0'));
      deps.dispose();
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
    },
  );

  testWidgets(
    'reduced motion stops skeleton pulse while a read remains pending',
    (tester) async {
      final p = Pending<List<AppNotification>>();
      final c = NotificationsController(NotificationSource(p.read));
      addTearDown(c.dispose);
      await tester.pumpWidget(
        harness(NotificationsScreen(controller: c), reduced: true),
      );
      await tester.pumpAndSettle();
      expect(c.isLoading, isTrue);
      expect(tester.binding.transientCallbackCount, 0);
      p.completer.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada notifikasi.'), findsOneWidget);
    },
  );

  testWidgets('cancelling preparation ignores a late job response', (
    tester,
  ) async {
    final pending = Completer<PreviewResult>();
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => TextButton(
            child: const Text('Open'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(
                builder: (_) => ScanProcessingScreen(
                  urls: const ['https://contoh.com'],
                  preparePreview: () => pending.future,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Menyiapkan tautan.'), findsOneWidget);
    await tester.tap(find.text('Batalkan'));
    await tester.pumpAndSettle();
    pending.complete(const PrepareScanPreview()(['https://contoh.com']));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('reduced motion does not bypass pending startup', (tester) async {
    final p = Pending<ScanResult>();
    final c = ScanDetailController(p.read);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      harness(
        StartupGate(controller: c, child: const Text('Ready')),
        reduced: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 0);
    final deps = ScanResultsDependencies();
    p.completer.complete(deps.findResult('0'));
    deps.dispose();
    await tester.pumpAndSettle();
    expect(find.text('Ready'), findsOneWidget);
  });
  testWidgets('known Home and Profile actions work during pending reads', (
    tester,
  ) async {
    var actions = 0;
    final recent = Pending<List<RecentScan>>();
    final home = HomeController(RecentSource(recent.read));
    addTearDown(home.dispose);
    await tester.pumpWidget(
      harness(
        HomeScreen(
          controller: home,
          onNotifications: () {
            actions++;
          },
          onRecentScan: (_) {},
          onScan: () {
            actions++;
          },
          onPaste: noop,
          onQr: () {
            actions++;
          },
          onShare: () {
            actions++;
          },
          onHistory: noop,
          onProfile: noop,
        ),
      ),
    );
    for (final text in ['Mulai pindai', 'Pindai QR', 'Dari aplikasi lain']) {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pump();
    }
    expect(home.isLoading, isTrue);
    expect(actions, 3);
    final counts = Pending<AccountStats>();
    final profile = ProfileController(
      repository: AccountSource(counts.read),
      loadAccountStats: const LoadAccountStats(),
    );
    addTearDown(profile.dispose);
    await tester.pumpWidget(
      harness(
        ProfilePage(
          controller: profile,
          account: const UserAccount(
            id: '1',
            name: 'Test User',
            email: 'test@example.test',
          ),
          onSettings: () {
            actions++;
          },
          onSignOut: () {
            actions++;
          },
          onReportStatus: () {
            actions++;
          },
          onNotifications: () {
            actions++;
          },
        ),
      ),
    );
    for (final text in [
      'Pengaturan',
      'Status laporan',
      'Notifikasi',
      'Keluar akun',
    ]) {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pump();
    }
    expect(profile.isLoading, isTrue);
    expect(actions, 7);
  });

  testWidgets('History keeps pending search and scope when data arrives', (
    tester,
  ) async {
    final p = Pending<List<HistoryEntry>>();
    final c = HistoryController(
      repository: HistorySource(p.read),
      filterHistoryEntries: const FilterHistoryEntries(),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(harness(HistoryScreen(controller: c)));
    await tester.enterText(find.byType(TextField), 'kept-query');
    await tester.tap(find.text('Aman'));
    await tester.pump();
    await tester.ensureVisible(find.text('Arti kategori'));
    await tester.tap(find.text('Arti kategori'));
    await tester.pump();
    expect(c.isLoading, isTrue);
    expect(c.scope, 'Aman');
    p.completer.complete([]);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'kept-query',
    );
    expect(c.scope, 'Aman');
    expect(
      find.textContaining('menyamar untuk mengambil data pribadi'),
      findsOneWidget,
    );
  });

  testWidgets('pending results retain a working return action', (tester) async {
    final p = Pending<List<ScanResult>>();
    final c = ScanResultsController(
      repository: ResultsSource(p.read),
      summarizeScanResults: const SummarizeScanResults(),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) => TextButton(
            child: const Text('Start'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ScanResultScreen(controller: c, onOpenDetail: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.ensureVisible(find.text('Periksa URL lain'));
    await tester.tap(find.text('Periksa URL lain'));
    await tester.pumpAndSettle();
    expect(find.text('Start'), findsOneWidget);
    expect(c.isLoading, isTrue);
    p.completer.complete([]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
