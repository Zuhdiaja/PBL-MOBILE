import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/auth/presentation/widgets/auth_form.dart';
import 'package:pbl_semester5/theme/app_theme.dart';

void main() {
  for (final width in [150.0, 320.0, 390.0, 600.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('email divider centered at width=$width scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: linkGuardTheme(Brightness.light),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: AuthForm(
              title: 'Masuk.',
              subtitle: 'Lanjutkan untuk melihat riwayat Anda.',
              fields: const [],
              actionLabel: 'Masuk',
              footerPrompt: 'Belum punya akun?',
              footerAction: 'Daftar sekarang',
              onFooterTap: () {},
              onSubmit: () {},
            ),
          ),
        );
        final label = tester.getRect(find.text('atau dengan email'));
        final left = tester.getRect(find.byType(Divider).first);
        final right = tester.getRect(find.byType(Divider).last);
        expect(label.center.dx, closeTo(width / 2, .01));
        expect(left.width, closeTo(right.width, .01));
        expect(label.left - left.right, closeTo(right.left - label.right, .01));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
