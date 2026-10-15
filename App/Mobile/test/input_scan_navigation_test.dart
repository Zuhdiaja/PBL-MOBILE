import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_semester5/data/scan_result.dart';
import 'package:pbl_semester5/features/scan_results/presentation/pages/scan_detail_screen.dart';

import 'scan_flow_test.dart' show openApp, tapVisible;

void main() {
  testWidgets('home summary opens the original detail through the shell', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.text(demoScanResults[1].url));
    expect(find.text('Detail hasil'), findsOneWidget);
    expect(
      tester.widget<ScanDetailScreen>(find.byType(ScanDetailScreen)).result.url,
      demoScanResults[1].url,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Halo, Nadia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'preview continues to existing results and returns to the URL draft',
    (tester) async {
      await openApp(tester);
      await tapVisible(tester, find.text('Mulai pindai'));
      await tester.enterText(
        find.byType(TextFormField),
        'https://contoh.com/draft',
      );
      await tapVisible(tester, find.text('Periksa URL'));
      await tapVisible(tester, find.text('Lihat hasil contoh'));
      expect(find.text('Hasil pindai'), findsOneWidget);
      expect(find.textContaining('Hasil simulasi'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Pindai URL'), findsOneWidget);
      expect(find.text('https://contoh.com/draft'), findsOneWidget);
      expect(find.text('Pratinjau pemeriksaan'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('sharing has fresh route state when it is reopened', (
    tester,
  ) async {
    await openApp(tester);
    await tapVisible(tester, find.text('Dari aplikasi lain'));
    await tapVisible(tester, find.text('Gunakan tautan contoh'));
    expect(find.text('https://contoh.com/artikel'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Dari aplikasi lain'));
    expect(find.text('Belum ada tautan'), findsOneWidget);
    expect(find.text('https://contoh.com/artikel'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
