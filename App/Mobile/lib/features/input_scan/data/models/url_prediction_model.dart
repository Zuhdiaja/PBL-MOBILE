import '../../../scan_results/domain/entities/scan_category.dart';
import '../../domain/entities/url_prediction.dart';

/// Maps the `scan` object returned by `/api/v1/mobile/scan`.
class UrlPredictionModel {
  const UrlPredictionModel({
    required this.scanId,
    required this.url,
    required this.category,
    required this.score,
    required this.scoreKind,
    this.modelRunId,
    this.createdAt,
  });

  factory UrlPredictionModel.fromJson(Map<String, dynamic> json) {
    final scanId = json['scan_id'];
    final url = json['url'];
    final category = json['category'];
    if (scanId is! String || url is! String || category is! String) {
      throw const FormatException('Respons pemindaian tidak dikenali.');
    }
    final score = json['score'];
    return UrlPredictionModel(
      scanId: scanId,
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

  final String scanId;
  final String url;
  final String category;
  final double score;
  final String scoreKind;
  final String? modelRunId;
  final DateTime? createdAt;

  UrlPrediction toEntity() => UrlPrediction(
    scanId: scanId,
    url: url,
    category: category,
    score: score,
    scoreKind: scoreKind,
    modelRunId: modelRunId,
    createdAt: createdAt,
  );
}
