/// Classification result for a single scanned URL.
///
/// Presentation concerns such as colors and icons stay outside the domain.
class ScanResult {
  const ScanResult({
    required this.id,
    required this.url,
    required this.category,
    required this.riskLevel,
    required this.confidence,
    required this.isSafe,
    required this.scanTime,
    required this.modelName,
    required this.method,
    this.recommendation,
    this.indicators,
  });

  final String id;
  final String url;
  final String category;
  final String riskLevel;
  final int confidence;
  final bool isSafe;
  final String scanTime;
  final String modelName;
  final String method;
  final String? recommendation;
  final List<String>? indicators;

  /// Recommendation shown when the source did not provide one.
  String get resolvedRecommendation =>
      recommendation ??
      (isSafe
          ? 'URL ini tampak aman dalam contoh analisis. Tetap periksa alamat domain sebelum memasukkan data pribadi.'
          : 'PERINGATAN: Tautan terdeteksi berpotensi bahaya ($category). Disarankan untuk tidak memasukkan data pribadi atau kredensial.');

  /// Indicators shown when the source did not provide them.
  List<String> get resolvedIndicators =>
      indicators ??
      (isSafe
          ? const [
              'Struktur domain terlihat wajar',
              'Tidak ada pola berisiko pada contoh URL',
            ]
          : const [
              'Domain menggunakan nama merek terkenal secara tidak sah',
              'Terdeteksi struktur URL dengan indikasi manipulasi',
            ]);
}

/// Aggregate counts shown above the result list.
class ScanResultSummary {
  const ScanResultSummary({
    required this.totalCount,
    required this.safeCount,
    required this.attentionCount,
  });

  final int totalCount;
  final int safeCount;
  final int attentionCount;
}
