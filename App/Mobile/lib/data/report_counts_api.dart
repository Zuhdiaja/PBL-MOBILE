import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/data/datasources/token_store.dart';

/// Counts of the signed-in user's reports, used by the profile screen.
class ReportCounts {
  const ReportCounts({required this.total, required this.pending});

  const ReportCounts.empty() : total = 0, pending = 0;

  final int total;

  /// Reports still waiting for the admin (`submitted` or `review`).
  final int pending;
}

/// Failure raised while reading the report counts from the API.
class ReportCountsException implements Exception {
  const ReportCountsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads `/api/v1/mobile/reports/summary`.
class ReportCountsApi {
  ReportCountsApi({
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

  Future<ReportCounts> summary() async {
    final token = await tokenStore.read();
    if (token == null) {
      throw const ReportCountsException(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }
    final uri = Uri.parse('$baseUrl/api/v1/mobile/reports/summary');

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
      throw const ReportCountsException(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    if (response.statusCode == 401) {
      throw const ReportCountsException(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }
    if (response.statusCode != 200) {
      throw const ReportCountsException('Jumlah laporan belum dapat dimuat.');
    }

    final payload = _decode(response);
    return ReportCounts(
      total: payload['total'] is int ? payload['total'] as int : 0,
      pending: payload['pending'] is int ? payload['pending'] as int : 0,
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
}
