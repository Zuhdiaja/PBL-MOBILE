import 'dart:convert';

import 'package:http/http.dart' as http;

import '../features/auth/data/datasources/token_store.dart';
import '../features/scan_results/domain/entities/scan_category.dart';

/// One stored scan as returned by `/api/v1/mobile/scans`.
///
/// This is a shared data-layer record: the history, home, and profile features
/// each map it onto their own model instead of re-implementing the request.
class ScanRecord {
  const ScanRecord({
    required this.id,
    required this.url,
    required this.category,
    required this.score,
    required this.scoreKind,
    this.modelRunId,
    this.createdAt,
  });

  final String id;
  final String url;

  /// Canonical class name, e.g. `Phishing` or `Legitimate`.
  final String category;

  /// `LinearSVC` margin; not a probability.
  final double score;
  final String scoreKind;
  final String? modelRunId;
  final DateTime? createdAt;

  bool get isSafe => ScanCategory.isSafe(category);
  bool get hasMarginScore => scoreKind == 'margin';

  String get formattedScore => score.toStringAsFixed(4);
}

/// One page of the caller's scans.
class ScansPage {
  const ScansPage({
    required this.items,
    required this.page,
    required this.pageCount,
    required this.rowCount,
  });

  final List<ScanRecord> items;
  final int page;
  final int pageCount;
  final int rowCount;
}

/// Counts used by the statistics and profile screens.
class ScanCounts {
  const ScanCounts({
    required this.total,
    required this.safe,
    required this.unsafe,
    required this.byCategory,
    this.weekly = const {},
  });

  const ScanCounts.empty()
    : total = 0,
      safe = 0,
      unsafe = 0,
      byCategory = const {},
      weekly = const {};

  final int total;
  final int safe;
  final int unsafe;

  /// Canonical category name to number of scans.
  final Map<String, int> byCategory;
  final Map<DateTime, int> weekly;

  int countOf(String category) => byCategory[category] ?? 0;
}

/// Failure raised while reading the scan history from the API.
class ScansApiException implements Exception {
  const ScansApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads the signed-in user's scans from the LinkGuard API.
class ScansApi {
  ScansApi({
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

  /// Every scan of the account, newest first.
  Future<List<ScanRecord>> listAll() async {
    final records = <ScanRecord>[];
    var page = 1;
    var pageCount = 1;
    while (page <= pageCount) {
      final result = await list(page: page);
      records.addAll(result.items);
      pageCount = result.pageCount;
      page++;
    }
    return records;
  }

  Future<ScansPage> list({
    int page = 1,
    String search = '',
    String? category,
    String scope = 'all',
  }) async {
    final payload = await _get(
      '/api/v1/mobile/scans',
      query: {
        'page': '$page',
        'page_size': '$_pageSize',
        if (search.isNotEmpty) 'search': search,
        'category': ?category,
        if (scope != 'all') 'scope': scope,
      },
    );
    final items = payload['items'];
    if (items is! List) {
      throw const ScansApiException('Respons server tidak dikenali.');
    }
    return ScansPage(
      items: [
        for (final item in items)
          if (item is Map<String, dynamic>) _record(item),
      ],
      page: payload['page'] is int ? payload['page'] as int : page,
      pageCount: payload['page_count'] is int
          ? payload['page_count'] as int
          : 1,
      rowCount: payload['row_count'] is int ? payload['row_count'] as int : 0,
    );
  }

  Future<ScanRecord> detail(String id) async {
    final payload = await _get(
      '/api/v1/mobile/scans/${Uri.encodeComponent(id)}',
    );
    if (payload['scan'] case final Map<String, dynamic> scan)
      return _record(scan);
    throw const ScansApiException('Respons server tidak dikenali.');
  }

  Future<ScanCounts> summary({bool weekly = false}) async {
    final payload = await _get(
      '/api/v1/mobile/scans/summary',
      query: weekly ? {'period': '7d'} : null,
    );
    final raw = payload['by_category'];
    final byCategory = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final count = entry.value;
        if (count is int) {
          byCategory[ScanCategory.fromRaw('${entry.key}')] = count;
        }
      }
    }
    return ScanCounts(
      total: payload['total'] is int ? payload['total'] as int : 0,
      safe: payload['safe'] is int ? payload['safe'] as int : 0,
      unsafe: payload['unsafe'] is int ? payload['unsafe'] as int : 0,
      byCategory: byCategory,
      weekly: {
        if (payload['weekly'] case final List days)
          for (final day in days)
            if (day case {'date': final String date, 'count': final int count})
              if (DateTime.tryParse(date) case final DateTime parsed)
                parsed: count,
      },
    );
  }

  ScanRecord _record(Map<String, dynamic> json) {
    final id = json['scan_id'];
    final url = json['url'];
    final category = json['category'];
    if (id is! String || url is! String || category is! String) {
      throw const ScansApiException('Respons server tidak dikenali.');
    }
    final score = json['score'];
    return ScanRecord(
      id: id,
      url: url,
      category: ScanCategory.fromRaw(category),
      score: score is num ? score.toDouble() : 0,
      scoreKind: (json['score_kind'] ?? 'margin').toString(),
      modelRunId: switch (json['model_run_id']) {
        final String value when value.isNotEmpty => value,
        _ => null,
      },
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
  }) async {
    final token = await tokenStore.read();
    if (token == null) {
      throw const ScansApiException(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);

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
      throw const ScansApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    if (response.statusCode == 200) return _decode(response);
    if (response.statusCode == 401) {
      throw const ScansApiException(
        'Sesi Anda sudah berakhir. Silakan masuk kembali.',
      );
    }
    throw ScansApiException(
      _message(response, 'Riwayat pemindaian belum dapat dimuat.'),
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
