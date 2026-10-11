import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/history/presentation/widgets/history_widgets.dart';
import 'package:pbl_semester5/features/history/presentation/widgets/report_status_widgets.dart';

import 'scan_flow_test.dart' show openApp, tapVisible;

void main() {
  testWidgets('history tab filters the sample entries and opens the detail', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Riwayat').last);
    await tester.pumpAndSettle();

    expect(find.text('Riwayat scan'), findsOneWidget);
    expect(find.text('8 URL pernah diperiksa'), findsOneWidget);
    expect(find.byType(HistoryRow), findsNWidgets(8));

    await tapVisible(
      tester,
      find.widgetWithText(HistoryFilterChip, 'Phishing'),
    );
    expect(find.byType(HistoryRow), findsNWidgets(2));

    await tapVisible(tester, find.byType(HistoryRow).first);
    expect(find.text('Detail hasil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics tab shows the sample activity summary', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Statistik').last);
    await tester.pumpAndSettle();

    expect(find.text('Ringkasan aktivitas pemeriksaan'), findsOneWidget);
    expect(find.text('Aktivitas 7 hari'), findsOneWidget);
    expect(find.text('Proporsi URL aman'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('report status opens the detail timeline', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Status laporan'));
    expect(find.text('3 laporan pernah dikirim'), findsOneWidget);

    await tapVisible(tester, find.byType(ReportStatusCard).first);
    expect(find.text('Detail laporan'), findsOneWidget);
    expect(find.text('Linimasa status'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications can be marked as read', (tester) async {
    await openApp(tester);
    await tester.tap(find.byTooltip('Notifikasi'));
    await tester.pumpAndSettle();

    expect(find.text('2 notifikasi belum dibaca'), findsOneWidget);

    await tapVisible(tester, find.text('Tandai semua dibaca'));
    expect(find.text('Semua notifikasi telah dibaca'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
