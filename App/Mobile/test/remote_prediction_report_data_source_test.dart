import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_semester5/features/auth/data/datasources/token_store.dart';
import 'package:pbl_semester5/features/scan_results/data/datasources/remote_prediction_report_data_source.dart';
import 'package:pbl_semester5/features/scan_results/domain/entities/prediction_report.dart';

const _baseUrl = 'http://api.test';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

Map<String, Object> _created({int id = 42}) => {
  'report': {
    'id': id,
    'url': 'contoh.example.test',
    'report_type': 'False Negative',
    'reported_category': 'Phishing',
    'status': 'submitted',
    'notes': 'Meniru halaman login.',
    'created_at': '2026-11-11T09:00:00+00:00',
  },
  'message': 'Laporan berhasil dikirim.',
};

RemotePredictionReportDataSource build(
  MockClient client, {
  TokenStore? tokenStore,
}) => RemotePredictionReportDataSource(
  baseUrl: _baseUrl,
  tokenStore: tokenStore ?? MemoryTokenStore('session-token'),
  client: client,
);

const _report = PredictionReport(
  url: 'contoh.example.test',
  type: ReportType.falseNegative,
  category: 'Phishing',
  notes: 'Meniru halaman login.',
);

void main() {
  group('RemotePredictionReportDataSource', () {
    test('posts the correction and returns the created report', () async {
      final source = build(
        MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), '$_baseUrl/api/v1/mobile/reports');
          expect(request.headers['Authorization'], 'Bearer session-token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['url'], 'contoh.example.test');
          expect(body['type'], 'False Negative');
          expect(body['category'], 'Phishing');
          expect(body['notes'], 'Meniru halaman login.');
          return _json(_created(), 201);
        }),
      );

      final report = await source.write(_report);

      expect(report.id, 42);
      expect(report.status, 'submitted');
    });

    test('sends a false positive as the API type name', () async {
      final source = build(
        MockClient((request) async {
          expect(jsonDecode(request.body)['type'], 'False Positive');
          return _json(_created(), 201);
        }),
      );

      await source.write(
        const PredictionReport(
          url: 'contoh.example.test',
          type: ReportType.falsePositive,
          category: 'Aman / Benign',
        ),
      );
    });

    test('fails without a token and never calls the API', () async {
      var called = false;
      final source = build(
        MockClient((_) async {
          called = true;
          return _json(_created(), 201);
        }),
        tokenStore: MemoryTokenStore(),
      );

      expect(
        () => source.write(_report),
        throwsA(
          isA<ScanResultsFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Sesi Anda sudah berakhir'),
          ),
        ),
      );
      expect(called, isFalse);
    });

    test('maps 401 to an expired session message', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'unauthorized',
              'message': 'Silakan masuk kembali.',
            },
          }, 401),
        ),
      );

      expect(
        () => source.write(_report),
        throwsA(
          isA<ScanResultsFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Sesi Anda sudah berakhir'),
          ),
        ),
      );
    });

    test('maps 429 to a rate limit message', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {'code': 'rate_limited'},
          }, 429),
        ),
      );

      expect(
        () => source.write(_report),
        throwsA(
          isA<ScanResultsFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Terlalu banyak laporan'),
          ),
        ),
      );
    });

    test('passes the validation message of the API through', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'error': {
              'code': 'invalid_category',
              'message': 'Kategori laporan tidak valid.',
            },
          }, 400),
        ),
      );

      expect(
        () => source.write(_report),
        throwsA(
          isA<ScanResultsFailure>().having(
            (failure) => failure.message,
            'message',
            'Kategori laporan tidak valid.',
          ),
        ),
      );
    });

    test('turns network errors into a friendly failure', () async {
      final source = build(MockClient((_) async => throw Exception('offline')));

      expect(
        () => source.write(_report),
        throwsA(
          isA<ScanResultsFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Tidak dapat terhubung'),
          ),
        ),
      );
    });

    test('rejects a success response without a report id', () async {
      final source = build(
        MockClient(
          (_) async => _json({
            'report': {'status': 'submitted'},
          }, 201),
        ),
      );

      expect(() => source.write(_report), throwsA(isA<ScanResultsFailure>()));
    });
  });
}
