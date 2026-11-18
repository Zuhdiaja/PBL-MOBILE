import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_semester5/data/scans_api.dart';
import 'package:pbl_semester5/features/auth/data/datasources/token_store.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/scan_category.dart';

const _baseUrl = 'http://api.test';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

Map<String, Object?> _scan({
  String id = 'scan-1',
  String category = 'phishing',
  String createdAt = '2026-11-17T09:00:00+00:00',
}) => {
  'scan_id': id,
  'url': 'https://contoh.test/login',
  'category': category,
  'score': 1.4631,
  'score_kind': 'margin',
  'model_run_id': 'run-abcdef123456',
  'created_at': createdAt,
};

Map<String, Object> _page({
  List<Map<String, Object?>>? items,
  int page = 1,
  int pageCount = 1,
}) => {
  'items': items ?? [_scan()],
  'page': page,
  'page_size': 100,
  'row_count': items?.length ?? 1,
  'page_count': pageCount,
};

ScansApi build(MockClient client, {TokenStore? tokenStore}) => ScansApi(
  baseUrl: _baseUrl,
  tokenStore: tokenStore ?? MemoryTokenStore('session-token'),
  client: client,
);

void main() {
  group('ScansApi.list', () {
    test('maps a stored scan and sends the bearer token', () async {
      final api = build(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/mobile/scans');
          expect(request.url.queryParameters['page_size'], '100');
          expect(request.headers['Authorization'], 'Bearer session-token');
          return _json(_page(), 200);
        }),
      );

      final page = await api.list();

      final record = page.items.single;
      expect(record.id, 'scan-1');
      expect(record.category, ScanCategory.phishing);
      expect(record.isSafe, isFalse);
      expect(record.score, closeTo(1.4631, 0.0001));
      expect(record.hasMarginScore, isTrue);
      expect(record.modelRunId, 'run-abcdef123456');
    });

    test('keeps legitimate apart from benign and marks it safe', () async {
      final api = build(
        MockClient(
          (_) async => _json(
            _page(
              items: [_scan(id: 'a', category: 'legitimate')],
            ),
            200,
          ),
        ),
      );

      final record = (await api.list()).items.single;

      expect(record.category, ScanCategory.legitimate);
      expect(record.category, isNot(ScanCategory.benign));
      expect(record.isSafe, isTrue);
    });

    test('walks every page', () async {
      final requested = <String?>[];
      final api = build(
        MockClient((request) async {
          final page = request.url.queryParameters['page'];
          requested.add(page);
          return _json(
            _page(
              items: [_scan(id: 'scan-$page')],
              page: page == '1' ? 1 : 2,
              pageCount: 2,
            ),
            200,
          );
        }),
      );

      final records = await api.listAll();

      expect(requested, ['1', '2']);
      expect(records.length, 2);
    });

    test('fails without a token and never calls the API', () async {
      var called = false;
      final api = build(
        MockClient((_) async {
          called = true;
          return _json(_page(), 200);
        }),
        tokenStore: MemoryTokenStore(),
      );

      expect(
        () => api.list(),
        throwsA(
          isA<ScansApiException>().having(
            (failure) => failure.message,
            'message',
            contains('Sesi Anda sudah berakhir'),
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('maps 401 to an expired session message', () async {
      final api = build(
        MockClient(
          (_) async => _json({
            'error': {'code': 'unauthorized', 'message': 'Silakan masuk.'},
          }, 401),
        ),
      );

      expect(() => api.list(), throwsA(isA<ScansApiException>()));
    });

    test('rejects a payload without an item list', () async {
      final api = build(MockClient((_) async => _json({'page': 1}, 200)));

      expect(
        () => api.list(),
        throwsA(
          isA<ScansApiException>().having(
            (failure) => failure.message,
            'message',
            contains('tidak dikenali'),
          ),
        ),
      );
    });

    test('turns network errors into a friendly failure', () async {
      final api = build(MockClient((_) async => throw Exception('offline')));

      expect(
        () => api.list(),
        throwsA(
          isA<ScansApiException>().having(
            (failure) => failure.message,
            'message',
            contains('Tidak dapat terhubung'),
          ),
        ),
      );
    });
  });

  group('ScansApi.summary', () {
    test('maps the counts and canonicalises category keys', () async {
      final api = build(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/mobile/scans/summary');
          return _json({
            'total': 5,
            'safe': 2,
            'unsafe': 3,
            'by_category': {
              'benign': 1,
              'legitimate': 1,
              'phishing': 2,
              'malware': 1,
            },
          }, 200);
        }),
      );

      final counts = await api.summary();

      expect(counts.total, 5);
      expect(counts.safe, 2);
      expect(counts.unsafe, 3);
      expect(counts.countOf(ScanCategory.legitimate), 1);
      expect(counts.countOf(ScanCategory.benign), 1);
      expect(counts.countOf(ScanCategory.phishing), 2);
    });

    test('returns zeros for an account without scans', () async {
      final api = build(
        MockClient(
          (_) async => _json({
            'total': 0,
            'safe': 0,
            'unsafe': 0,
            'by_category': <String, int>{},
          }, 200),
        ),
      );

      final counts = await api.summary();

      expect(counts.total, 0);
      expect(counts.byCategory, isEmpty);
    });
  });
}
