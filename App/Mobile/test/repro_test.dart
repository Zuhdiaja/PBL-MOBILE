import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/app/scan_results_dependencies.dart';
import 'package:pbl_semester5/screens/report_prediction_screen.dart';
import 'package:pbl_semester5/screens/scan_detail_screen.dart';
import 'package:pbl_semester5/screens/scan_result_screen.dart';
import 'package:pbl_semester5/theme/app_colors.dart';

Widget harness(Widget child, double scale) => MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue),
    useMaterial3: true,
  ),
  builder: (context, c) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: c!,
  ),
  home: child,
);

void main() {
  late ScanResultsDependencies dependencies;

  setUp(() => dependencies = ScanResultsDependencies());
  tearDown(() => dependencies.dispose());

  final cases = <String, Widget Function()>{
    'report': () => ReportPredictionScreen(
      controller: dependencies.createReportController(
        dependencies.findResult('0'),
      ),
    ),
    'detail': () => ScanDetailScreen(
      result: dependencies.findResult('0'),
      onReport: (_) {},
    ),
    'result': () => ScanResultScreen(
      controller: dependencies.scanResults,
      onOpenDetail: (_) {},
    ),
  };

  test('dependencies expose example results', () {
    dependencies.scanResults.load();
    expect(dependencies.scanResults.summary.totalCount, greaterThan(0));
  });

  for (final entry in cases.entries) {
    testWidgets('detail-info ${entry.key}', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        final nodes =
            d.informationCollector?.call() ?? const <DiagnosticsNode>[];
        final creator = nodes
            .map((n) => n.toString())
            .where((s) => s.contains('creator:'))
            .map((s) => s.split('\n').first.trim())
            .toSet()
            .join(' ;; ');
        // ignore: avoid_print
        print('@@@ ${entry.key} :: $creator');
      };
      addTearDown(() => FlutterError.onError = prev);

      await tester.pumpWidget(harness(entry.value(), 1.8));
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print('@@@ END ${entry.key}');
    });
  }
}
