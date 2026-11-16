import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_semester5/features/input_scan/domain/entities/scan_failure.dart';
import 'package:pbl_semester5/features/input_scan/domain/entities/url_prediction.dart';
import 'package:pbl_semester5/features/input_scan/domain/repositories/url_predictor.dart';
import 'package:pbl_semester5/features/input_scan/domain/usecases/submit_scan.dart';

/// Predictor that answers from a fixed table.
class _TablePredictor implements UrlPredictor {
  _TablePredictor(this._answers);

  final Map<String, Object> _answers;
  final calls = <String>[];

  @override
  Future<UrlPrediction> predict(String url) async {
    calls.add(url);
    final answer = _answers[url] ?? const ScanFailure('Tidak diketahui.');
    if (answer is ScanFailure) throw answer;
    return answer as UrlPrediction;
  }
}

UrlPrediction _prediction(String url) => UrlPrediction(
  scanId: 'scan-$url',
  url: url,
  category: 'Benign',
  score: 1.1,
  scoreKind: 'margin',
);

void main() {
  const submit = SubmitScan();

  group('SubmitScan', () {
    test('returns every prediction when all URLs succeed', () async {
      final predictor = _TablePredictor({
        'https://a.test': _prediction('https://a.test'),
        'https://b.test': _prediction('https://b.test'),
      });

      final result = await submit([
        'https://a.test',
        'https://b.test',
      ], predictor);

      expect(result.succeeded, 2);
      expect(result.failed, 0);
      expect(result.attempts.every((a) => a.prediction != null), isTrue);
    });

    test('keeps going after one URL fails', () async {
      final predictor = _TablePredictor({
        'https://a.test': _prediction('https://a.test'),
        'https://b.test': const ScanFailure(
          'Tidak dapat terhubung.',
          kind: ScanFailureKind.network,
        ),
        'https://c.test': _prediction('https://c.test'),
      });

      final result = await submit([
        'https://a.test',
        'https://b.test',
        'https://c.test',
      ], predictor);

      expect(result.succeeded, 2);
      expect(result.failed, 1);
      expect(result.attempts[1].failure?.kind, ScanFailureKind.network);
      expect(predictor.calls, [
        'https://a.test',
        'https://b.test',
        'https://c.test',
      ]);
    });

    test('stops at once when the session expired', () async {
      final predictor = _TablePredictor({
        'https://a.test': _prediction('https://a.test'),
        'https://b.test': const ScanFailure(
          'Sesi berakhir.',
          kind: ScanFailureKind.auth,
        ),
        'https://c.test': _prediction('https://c.test'),
      });

      await expectLater(
        submit([
          'https://a.test',
          'https://b.test',
          'https://c.test',
        ], predictor),
        throwsA(isA<ScanFailure>().having((f) => f.isFatal, 'fatal', isTrue)),
      );
      expect(predictor.calls, ['https://a.test', 'https://b.test']);
    });

    test('reports progress after each URL', () async {
      final progress = <String>[];
      final predictor = _TablePredictor({
        'https://a.test': _prediction('https://a.test'),
        'https://b.test': _prediction('https://b.test'),
      });

      await submit(
        ['https://a.test', 'https://b.test'],
        predictor,
        onProgress: (done, total) => progress.add('$done/$total'),
      );

      expect(progress, ['1/2', '2/2']);
    });

    test('stops issuing requests once cancelled', () async {
      final predictor = _TablePredictor({
        'https://a.test': _prediction('https://a.test'),
        'https://b.test': _prediction('https://b.test'),
      });
      var calls = 0;

      final result = await submit(
        ['https://a.test', 'https://b.test'],
        predictor,
        isCancelled: () => calls++ > 0,
      );

      expect(result.attempts.length, 1);
      expect(predictor.calls, ['https://a.test']);
    });
  });
}
