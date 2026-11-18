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
    this.score,
    this.scoreKind,
    this.modelRunId,
    this.isSimulated = false,
  });

  final String id;
  final String url;
  final String category;
  final String riskLevel;

  /// Percentage shown for example results; real scans use [score] instead.
  final int confidence;
  final bool isSafe;
  final String scanTime;
  final String modelName;
  final String method;
  final String? recommendation;
  final List<String>? indicators;

  /// Model score for real predictions, e.g. the `LinearSVC` margin.
  final double? score;

  /// How [score] must be read, e.g. `margin`.
  final String? scoreKind;

  /// Version of the model that produced a real prediction.
  final String? modelRunId;

  /// True when the entry comes from the example data rather than the API.
  final bool isSimulated;

  /// True when [score] is a margin, which is not a probability.
  bool get hasMarginScore => score != null && scoreKind == 'margin';

  /// Score formatted for the detail screen.
  String get formattedScore => score == null ? '—' : score!.toStringAsFixed(4);

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
