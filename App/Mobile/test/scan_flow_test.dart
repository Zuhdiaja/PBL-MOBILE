import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pbl_semester5/app/auth_dependencies.dart';
import 'package:pbl_semester5/main.dart';
import 'package:pbl_semester5/screens/main_shell.dart';

Future<void> openApp(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MyAppTestShell(textScale: textScale));
  await tester.pumpAndSettle();
}

class MyAppTestShell extends StatefulWidget {
  const MyAppTestShell({super.key, this.textScale = 1});

  final double textScale;

  @override
  State<MyAppTestShell> createState() => _MyAppTestShellState();
}

class _MyAppTestShellState extends State<MyAppTestShell> {
  final _auth = AuthDependencies();

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  void _signOut() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
    (route) => false,
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: (const MyApp().build(context) as MaterialApp).theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(widget.textScale)),
      child: child!,
    ),
    home: MainShell(auth: _auth, onSignOut: _signOut),
  );
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('scan method cards keep equal dimensions with wrapped text', (
    tester,
  ) async {
    await openApp(tester, size: const Size(426, 952));
    await tapVisible(tester, find.text('Mulai scan'));
    final qrCard = find
        .ancestor(
          of: find.text('Scan QR Code'),
          matching: find.byType(Material),
        )
        .first;
    final shareCard = find
        .ancestor(
          of: find.text('Dari aplikasi lain'),
          matching: find.byType(Material),
        )
        .first;
    expect(tester.getSize(qrCard), tester.getSize(shareCard));
    expect(tester.takeException(), isNull);
  });

  testWidgets('home shortcuts open QR and sharing; system back and tabs work', (
    tester,
  ) async {
    await openApp(tester);
    expect(find.text('Halo, Nadia'), findsOneWidget);
    expect(find.textContaining('Mockup v1.0'), findsNothing);

    await tapVisible(tester, find.text('Scan QR'));
    expect(find.text('Scan QR Code'), findsOneWidget);
    await tapVisible(tester, find.text('Pindai contoh QR'));
    expect(find.text('Pratinjau pemeriksaan'), findsOneWidget);
    expect(find.text('https://contoh.com'), findsOneWidget);
    expect(find.textContaining('Belum ada penilaian keamanan'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Halo, Nadia'), findsOneWidget);

    await tapVisible(tester, find.text('Bagikan link'));
    expect(find.text('Bagikan ke LinkGuard').first, findsOneWidget);
    await tester.tap(find.text('Scan').last);
    await tester.pumpAndSettle();
    expect(find.text('Scan URL'), findsOneWidget);
  });

  testWidgets(
    'URL form enforces five fields, validates, and preserves drafts across tabs',
    (tester) async {
      await openApp(tester);
      await tapVisible(tester, find.text('Mulai scan'));
      await tester.enterText(find.byType(TextFormField), 'bukan-url');
      await tapVisible(tester, find.text('Periksa URL'));
      expect(find.textContaining('Gunakan URL lengkap'), findsOneWidget);
      expect(find.text('Pratinjau pemeriksaan'), findsNothing);

      await tester.enterText(find.byType(TextFormField), 'https://contoh.com');
      await tester.tap(find.text('Beranda').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField))
            .controller!
            .text,
        'https://contoh.com',
      );

      for (var i = 0; i < 4; i++) {
        await tapVisible(tester, find.text('Tambah URL'));
      }
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text('5/5 URL'), findsOneWidget);
      final maxButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Maksimal 5 URL'),
      );
      expect(maxButton.onPressed, isNull);

      await tapVisible(tester, find.byTooltip('Hapus URL 5'));
      expect(find.byType(TextFormField), findsNWidgets(4));
      expect(find.text('4/5 URL'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        final field = find.byType(TextFormField).at(i);
        await tester.ensureVisible(field);
        await tester.enterText(field, 'https://contoh.com/$i');
      }
      await tapVisible(tester, find.text('Periksa URL'));
      expect(find.text('Pratinjau pemeriksaan'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        expect(find.text('https://contoh.com/$i'), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'paste shortcut fills the first URL and handles an empty clipboard',
    (tester) async {
      var clipboard = 'https://contoh.com/dari-clipboard';
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') return {'text': clipboard};
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await openApp(tester);
      await tapVisible(tester, find.text('Tempel URL'));
      expect(find.text(clipboard), findsOneWidget);
      clipboard = '';
      await tapVisible(tester, find.text('Tempel'));
      expect(
        find.textContaining('Belum ada teks untuk ditempel'),
        findsOneWidget,
      );
      expect(find.text('https://contoh.com/dari-clipboard'), findsOneWidget);
    },
  );

  testWidgets(
    'sharing previews an editable example and validates before continuing',
    (tester) async {
      await openApp(tester);
      await tapVisible(tester, find.text('Bagikan link'));
      final emptyButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Periksa URL'),
      );
      expect(emptyButton.onPressed, isNull);
      await tapVisible(tester, find.text('Gunakan tautan contoh'));
      expect(find.text('contoh.com'), findsOneWidget);
      expect(find.text('https://contoh.com/artikel'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'tautan-salah');
      await tapVisible(tester, find.text('Periksa URL'));
      expect(find.textContaining('Gunakan URL lengkap'), findsOneWidget);
      expect(find.text('Pratinjau pemeriksaan'), findsNothing);

      await tester.enterText(
        find.byType(TextFormField),
        'https://contoh.com/diubah',
      );
      await tapVisible(tester, find.text('Periksa URL'));
      expect(find.text('Pratinjau pemeriksaan'), findsOneWidget);
      expect(find.text('https://contoh.com/diubah'), findsWidgets);
      expect(
        find.textContaining('Belum ada penilaian keamanan'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(412, 915)]) {
    testWidgets('four screens fit $size with larger text and keyboard insets', (
      tester,
    ) async {
      await openApp(tester, size: size, textScale: 1.3);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Scan').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Periksa URL'));
      expect(tester.takeException(), isNull);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('Scan QR Code'));
      expect(tester.takeException(), isNull);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Dari aplikasi lain'));
      await tapVisible(tester, find.text('Gunakan tautan contoh'));
      expect(tester.takeException(), isNull);
    });
  }
}
