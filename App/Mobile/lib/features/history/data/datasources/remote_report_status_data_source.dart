import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../auth/data/datasources/token_store.dart';
import '../../domain/entities/history_failure.dart';
import '../models/report_status_model.dart';
import 'report_status_data_source.dart';

/// Reads the signed-in user's own reports from `/api/v1/mobile/reports`.
///
/// The endpoint is scoped by the bearer token, so the list can only contain
/// reports the current account submitted.
class RemoteReportStatusDataSource implements ReportStatusDataSource {
  RemoteReportStatusDataSource({
    required String baseUrl,
    required this.tokenStore,
    http.Client? client,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _client = client ?? http.Client();

  final String baseUrl;
  final TokenStore tokenStore;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);
  static const _pageSize = 100;
  static const _maxPages = 10;

  @override
  Future<List<ReportStatusModel>> readReports() async {
    final token = await tokenStore.read();
    if (token == null) {
      throw const HistoryFailure(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }

    final reports = <ReportStatusModel>[];
    var page = 1;
    var pageCount = 1;
    while (page <= pageCount && page <= _maxPages) {
      final payload = await _fetch(token, page);
      final items = payload['items'];
      if (items is! List) {
        throw const HistoryFailure('Respons server tidak dikenali.');
      }
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          reports.add(ReportStatusModel.fromJson(item));
        }
      }
      final reportedPages = payload['page_count'];
      pageCount = reportedPages is int && reportedPages > 0 ? reportedPages : 1;
      page++;
    }
    return reports;
  }

  Future<Map<String, dynamic>> _fetch(String token, int page) async {
    final uri = Uri.parse('$baseUrl/api/v1/mobile/reports')
        .replace(queryParameters: {'page': '$page', 'page_size': '$_pageSize'});

    final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
    } catch (_) {
      throw const HistoryFailure(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    if (response.statusCode == 200) return _decode(response);
    if (response.statusCode == 401) {
      throw const HistoryFailure(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }
    throw HistoryFailure(
      _message(response, 'Laporan belum dapat dimuat. Coba lagi.'),
    );
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? data : const {};
    } catch (_) {
      return const {};
    }
  }

  String _message(http.Response response, String fallback) {
    final error = _decode(response)['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    return fallback;
  }
}
