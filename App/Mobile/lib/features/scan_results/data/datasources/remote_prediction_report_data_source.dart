import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../auth/data/datasources/token_store.dart';
import '../../domain/entities/prediction_report.dart';
import '../models/submitted_prediction_report_model.dart';
import 'prediction_report_data_source.dart';

/// Sends corrections to `/api/v1/mobile/reports` on the LinkGuard API.
///
/// The endpoint is bound to the signed-in mobile account through the bearer
/// token, so the server records the owner of every report.
class RemotePredictionReportDataSource implements PredictionReportDataSource {
  RemotePredictionReportDataSource({
    required String baseUrl,
    required this.tokenStore,
    http.Client? client,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       _client = client ?? http.Client();

  /// Categories the API accepts, spelled as the report form shows them.
  static const categories = [
    'Aman / Benign',
    'Phishing',
    'Malware',
    'Spam',
    'Defacement',
    'Exploit',
  ];

  final String baseUrl;
  final TokenStore tokenStore;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);

  @override
  List<String> readCategories() => categories;

  Uri get _uri => Uri.parse('$baseUrl/api/v1/mobile/reports');

  @override
  Future<SubmittedPredictionReportModel> write(PredictionReport report) async {
    final token = await tokenStore.read();
    if (token == null) {
      throw const ScanResultsFailure(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            _uri,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'url': report.url,
              'type': report.type == ReportType.falsePositive
                  ? 'False Positive'
                  : 'False Negative',
              'category': report.category,
              'notes': report.notes,
            }),
          )
          .timeout(_timeout);
    } catch (_) {
      throw const ScanResultsFailure(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    if (response.statusCode == 201) {
      final payload = _decode(response)['report'];
      if (payload is! Map<String, dynamic>) {
        throw const ScanResultsFailure('Respons server tidak dikenali.');
      }
      return SubmittedPredictionReportModel.fromJson(payload);
    }
    if (response.statusCode == 401) {
      throw const ScanResultsFailure(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }
    if (response.statusCode == 429) {
      throw const ScanResultsFailure(
        'Terlalu banyak laporan dalam waktu singkat. Coba lagi nanti.',
      );
    }
    throw ScanResultsFailure(
      _message(response, 'Laporan belum dapat dikirim. Coba lagi.'),
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
