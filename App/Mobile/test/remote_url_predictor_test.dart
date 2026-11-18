import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_semester5/features/auth/data/datasources/token_store.dart';
import 'package:pbl_semester5/features/input_scan/data/datasources/remote_url_predictor.dart';
import 'package:pbl_semester5/features/input_scan/domain/entities/scan_failure.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/scan_category.dart';

const _baseUrl = 'http://api.test';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

Map<String, Object> _scan({String category = 'phishing', num score = 1.4631}) =>
    {
      'scan': {
        'scan_id': 'scan-1',
        'url': 'https://contoh.test/login',
        'category': category,
        'score': score,
        'score_kind': 'margin',
        'model_run_id': 'run-abcdef123456',
        'created_at': '2026-11-16T09:00:00+00:00',
      },
      'message': 'Pemindaian selesai.',
    };

RemoteUrlPredictor build(MockClient client, {TokenStore? tokenStore}) =>
    RemoteUrlPredictor(
      baseUrl: _baseUrl,
      tokenStore: tokenStore ?? MemoryTokenStore('session-token'),
      client: client,
    );

void main() {
  group('RemoteUrlPredictor', () {
    test('posts one URL and maps the created scan', () async {
      final predictor = build(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), '$_baseUrl/api/v1/mobile/scan');
          expect(request.headers['Authorization'], 'Bearer session-token');
          expect(jsonDecode(request.body)['url'], 'https://contoh.test/login');
          return _json(_scan(), 201);
        }),
      );

      final prediction = await predictor.predict('https://contoh.test/login');

      expect(prediction.scanId, 'scan-1');
      expect(prediction.category, ScanCategory.phishing);
      expect(prediction.score, closeTo(1.4631, 0.0001));
      expect(prediction.isMarginScore, isTrue);
      expect(prediction.modelRunId, 'run-abcdef123456');
    });

    test('keeps legitimate apart from benign', () async {
      final predictor = build(
        MockClient((_) async => _json(_scan(category: 'legitimate'), 201)),
      );

      final prediction = await predictor.predict('https://contoh.test/login');

      expect(prediction.category, ScanCategory.legitimate);
      expect(prediction.category, isNot(ScanCategory.benign));
    });

    test('fails without a token and never calls the API', () async {
      var called = false;
      final predictor = build(
        MockClient((_) async {
          called = true;
          return _json(_scan(), 201);
        }),
        tokenStore: MemoryTokenStore(),
      );

      expect(
        () => predictor.predict('https://contoh.test/login'),
        throwsA(
          isA<ScanFailure>().having(
            (f) => f.kind,
            'kind',
            ScanFailureKind.auth,
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('maps 401 to a fatal session failure', () async {
      final predictor = build(
        MockClient(
          (_) async => _json({
            'error': {'code': 'unauthorized', 'message': 'Silakan masuk.'},
          }, 401),
        ),
      );

      expect(
        () => predictor.predict('https://contoh.test/login'),
        throwsA(isA<ScanFailure>().having((f) => f.isFatal, 'fatal', isTrue)),
      );
    });

    test('maps 429 to a rate limit failure', () async {
      final predictor = build(
        MockClient(
          (_) async => _json({
            'error': {'code': 'rate_limited'},
          }, 429),
        ),
      );

      expect(
        () => predictor.predict('https://contoh.test/login'),
        throwsA(
          isA<ScanFailure>().having(
            (f) => f.kind,
            'kind',
            ScanFailureKind.rateLimit,
          ),
        ),
      );
    });

    test('passes the 503 model message through', () async {
      final predictor = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'inference_unavailable',
              'message': 'Belum ada model aktif.',
            },
          }, 503),
        ),
      );

      expect(
        () => predictor.predict('https://contoh.test/login'),
        throwsA(
          isA<ScanFailure>()
              .having((f) => f.kind, 'kind', ScanFailureKind.model)
              .having((f) => f.message, 'message', 'Belum ada model aktif.'),
        ),
      );
    });

    test('maps 400 to a validation failure', () async {
      final predictor = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'invalid_url',
              'message': 'URL harus berupa teks 1-2048 karakter.',
            },
          }, 400),
        ),
      );

      expect(
        () => predictor.predict('x'),
        throwsA(
          isA<ScanFailure>().having(
            (f) => f.kind,
            'kind',
            ScanFailureKind.validation,
          ),
        ),
      );
    });

    test('turns network errors into a friendly failure', () async {
      final predictor = build(
        MockClient((_) async => throw Exception('offline')),
      );

      expect(
        () => predictor.predict('https://contoh.test/login'),
        throwsA(
          isA<ScanFailure>()
              .having((f) => f.kind, 'kind', ScanFailureKind.network)
              .having(
                (f) => f.message,
                'message',
                contains('Tidak dapat terhubung'),
              ),
        ),
      );
    });

    test('rejects a success response without a scan object', () async {
      final predictor = build(
        MockClient((_) async => _json({'message': 'ok'}, 201)),
      );

      expect(
        () => predictor.predict('https://contoh.test/login'),
        throwsA(isA<ScanFailure>()),
      );
    });
  });
}
