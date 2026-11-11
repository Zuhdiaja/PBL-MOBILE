import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_semester5/features/auth/data/datasources/token_store.dart';
import 'package:pbl_semester5/features/history/data/datasources/remote_report_status_data_source.dart';
import 'package:pbl_semester5/features/history/domain/entities/history_failure.dart';
import 'package:pbl_semester5/features/history/domain/entities/report_status.dart';

const _baseUrl = 'http://api.test';

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

Map<String, Object?> _report({
  int id = 1,
  String status = 'submitted',
  String createdAt = '2026-11-11T09:00:00+00:00',
}) => {
  'id': id,
  'url': 'contoh.example.test',
  'report_type': 'False Negative',
  'reported_category': 'Phishing',
  'status': status,
  'notes': 'Meniru halaman login.',
  'created_at': createdAt,
  'updated_at': createdAt,
};

Map<String, Object> _page({
  List<Map<String, Object?>>? items,
  int page = 1,
  int pageCount = 1,
}) => {
  'items': items ?? [_report()],
  'page': page,
  'page_size': 100,
  'row_count': items?.length ?? 1,
  'page_count': pageCount,
};

RemoteReportStatusDataSource build(
  MockClient client, {
  TokenStore? tokenStore,
}) => RemoteReportStatusDataSource(
  baseUrl: _baseUrl,
  tokenStore: tokenStore ?? MemoryTokenStore('session-token'),
  client: client,
);

void main() {
  group('RemoteReportStatusDataSource', () {
    test('reads the reports of the signed-in user', () async {
      final source = build(
        MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/api/v1/mobile/reports');
          expect(request.url.queryParameters['page_size'], '100');
          expect(request.headers['Authorization'], 'Bearer session-token');
          return _json(_page(), 200);
        }),
      );

      final reports = await source.readReports();

      expect(reports.length, 1);
      final entity = reports.single.toEntity();
      expect(entity.url, 'contoh.example.test');
      expect(entity.type, 'False Negative');
      expect(entity.reportedCategory, 'Phishing');
      expect(entity.notes, 'Meniru halaman login.');
    });

    test('maps every API status onto a report stage', () async {
      final source = build(
        MockClient(
          (_) async => _json(
            _page(
              items: [
                _report(id: 1, status: 'submitted'),
                _report(id: 2, status: 'review'),
                _report(id: 3, status: 'completed'),
                _report(id: 4, status: 'rejected'),
              ],
            ),
            200,
          ),
        ),
      );

      final stages = (await source.readReports())
          .map((model) => model.toEntity().stage)
          .toList();

      expect(stages, [
        ReportStage.submitted,
        ReportStage.review,
        ReportStage.completed,
        ReportStage.rejected,
      ]);
    });

    test('shows the submitted time in WIB', () async {
      final source = build(
        MockClient(
          (_) async => _json(
            _page(items: [_report(createdAt: '2026-11-11T09:05:00+00:00')]),
            200,
          ),
        ),
      );

      final entity = (await source.readReports()).single.toEntity();

      expect(entity.submittedTime, '11 Nov 2026, 16:05 WIB');
    });

    test('collects every page reported by the API', () async {
      final requestedPages = <String?>[];
      final source = build(
        MockClient((request) async {
          final page = request.url.queryParameters['page'];
          requestedPages.add(page);
          return _json(
            _page(
              items: [_report(id: page == '1' ? 1 : 2)],
              page: page == '1' ? 1 : 2,
              pageCount: 2,
            ),
            200,
          );
        }),
      );

      final reports = await source.readReports();

      expect(requestedPages, ['1', '2']);
      expect(reports.length, 2);
    });

    test('fails without a token and never calls the API', () async {
      var called = false;
      final source = build(
        MockClient((_) async {
          called = true;
          return _json(_page(), 200);
        }),
        tokenStore: MemoryTokenStore(),
      );

      expect(
        () => source.readReports(),
        throwsA(
          isA<HistoryFailure>().having(
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
        () => source.readReports(),
        throwsA(
          isA<HistoryFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Sesi Anda sudah berakhir'),
          ),
        ),
      );
    });

    test('rejects a payload without an item list', () async {
      final source = build(MockClient((_) async => _json({'page': 1}, 200)));

      expect(
        () => source.readReports(),
        throwsA(
          isA<HistoryFailure>().having(
            (failure) => failure.message,
            'message',
            contains('tidak dikenali'),
          ),
        ),
      );
    });

    test('turns network errors into a friendly failure', () async {
      final source = build(MockClient((_) async => throw Exception('offline')));

      expect(
        () => source.readReports(),
        throwsA(
          isA<HistoryFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Tidak dapat terhubung'),
          ),
        ),
      );
    });
  });
}
