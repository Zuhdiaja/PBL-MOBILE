import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../auth/data/datasources/token_store.dart';
import '../../domain/entities/scan_failure.dart';
import '../../domain/entities/url_prediction.dart';
import '../../domain/repositories/url_predictor.dart';
import '../models/url_prediction_model.dart';

/// Checks a URL with `POST /api/v1/mobile/scan`.
///
/// The model runs on the server; the app only sends the URL and receives the
/// category, the margin, and the scan id.
class RemoteUrlPredictor implements UrlPredictor {
  RemoteUrlPredictor({
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

  static const _timeout = Duration(seconds: 20);

  Uri get _uri => Uri.parse('$baseUrl/api/v1/mobile/scan');

  @override
  Future<UrlPrediction> predict(String url) async {
    final token = await tokenStore.read();
    if (token == null) {
      throw const ScanFailure(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
        kind: ScanFailureKind.auth,
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
            body: jsonEncode({'url': url}),
          )
          .timeout(_timeout);
    } catch (_) {
      throw const ScanFailure(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
        kind: ScanFailureKind.network,
      );
    }

    if (response.statusCode == 201) {
      final payload = _decode(response)['scan'];
      if (payload is! Map<String, dynamic>) {
        throw const ScanFailure(
          'Respons server tidak dikenali.',
          kind: ScanFailureKind.unknown,
        );
      }
      try {
        return UrlPredictionModel.fromJson(payload).toEntity();
      } on FormatException {
        throw const ScanFailure(
          'Respons server tidak dikenali.',
          kind: ScanFailureKind.unknown,
        );
      }
    }
    if (response.statusCode == 401) {
      throw const ScanFailure(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
        kind: ScanFailureKind.auth,
      );
    }
    if (response.statusCode == 429) {
      throw const ScanFailure(
        'Terlalu banyak pemeriksaan. Coba lagi sebentar.',
        kind: ScanFailureKind.rateLimit,
      );
    }
    if (response.statusCode == 503) {
      throw ScanFailure(
        _message(response, 'Mesin pemeriksa belum terpasang.'),
        kind: ScanFailureKind.model,
      );
    }
    if (response.statusCode == 400) {
      throw ScanFailure(
        _message(response, 'URL tidak dapat diperiksa.'),
        kind: ScanFailureKind.validation,
      );
    }
    throw ScanFailure(
      _message(response, 'URL belum dapat diperiksa. Coba lagi.'),
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
