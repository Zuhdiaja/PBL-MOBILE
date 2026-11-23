import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_semester5/data/report_counts_api.dart';
import 'package:pbl_semester5/features/auth/data/datasources/token_store.dart';

const _baseUrl = 'http://api.test';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

ReportCountsApi build(MockClient client, {TokenStore? tokenStore}) =>
    ReportCountsApi(
      baseUrl: _baseUrl,
      tokenStore: tokenStore ?? MemoryTokenStore('session-token'),
      client: client,
    );

void main() {
  group('ReportCountsApi.summary', () {
    test('maps the counts and sends the bearer token', () async {
      final api = build(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/mobile/reports/summary');
          expect(request.headers['Authorization'], 'Bearer session-token');
          return _json({'total': 5, 'pending': 2, 'by_status': {}}, 200);
        }),
      );

      final counts = await api.summary();

      expect(counts.total, 5);
      expect(counts.pending, 2);
    });

    test('treats a missing field as zero', () async {
      final api = build(MockClient((_) async => _json({'total': 3}, 200)));

      final counts = await api.summary();

      expect(counts.total, 3);
      expect(counts.pending, 0);
    });

    test('reports an expired session instead of a generic failure', () async {
      final api = build(MockClient((_) async => _json({}, 401)));

      expect(
        () => api.summary(),
        throwsA(
          isA<ReportCountsException>().having(
            (error) => error.message,
            'message',
            contains('Sesi Anda sudah berakhir'),
          ),
        ),
      );
    });

    test('fails without a stored token', () async {
      final api = build(
        MockClient((_) async => _json({}, 200)),
        tokenStore: MemoryTokenStore(),
      );

      expect(
        () => api.summary(),
        throwsA(
          isA<ReportCountsException>().having(
            (error) => error.message,
            'message',
            contains('Sesi Anda sudah berakhir'),
          ),
        ),
      );
    });
  });
}
