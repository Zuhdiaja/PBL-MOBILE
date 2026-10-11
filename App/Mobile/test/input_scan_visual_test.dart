import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'scan_flow_test.dart' show openApp, tapVisible;

void main() {
  for (final page in ['home', 'url', 'qr', 'share']) {
    testWidgets('input scan keeps the existing $page appearance', (
      tester,
    ) async {
      await openApp(tester);
      switch (page) {
        case 'url':
          await tapVisible(tester, find.text('Mulai scan'));
          await tester.enterText(
            find.byType(TextFormField),
            'https://contoh.com',
          );
          FocusManager.instance.primaryFocus?.unfocus();
        case 'qr':
          await tapVisible(tester, find.text('Scan QR'));
        case 'share':
          await tapVisible(tester, find.text('Bagikan link'));
          await tapVisible(tester, find.text('Gunakan tautan contoh'));
      }
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/input_scan/$page.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
