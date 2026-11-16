import '../../../../data/scan_result.dart';
import '../../../input_scan/domain/entities/url_prediction.dart';
import '../../domain/entities/scan_category.dart';
import '../../domain/entities/scan_result.dart';

/// Maps both the legacy example model and a real API prediction onto the
/// domain entity.
class ScanResultModel {
  const ScanResultModel._({
    required this.id,
    required this.url,
    required this.category,
    required this.riskLevel,
    required this.confidence,
    required this.isSafe,
    required this.scanTime,
    required this.modelName,
    required this.method,
    required this.isSimulated,
    this.recommendation,
    this.indicators,
    this.score,
    this.scoreKind,
    this.modelRunId,
  });

  factory ScanResultModel.fromLegacy(String id, ScanResultItem item) =>
      ScanResultModel._(
        id: id,
        url: item.url,
        category: item.category,
        riskLevel: item.riskLevel,
        confidence: item.confidence,
        isSafe: item.isSafe,
        scanTime: item.scanTime,
        modelName: item.modelName,
        method: item.method,
        isSimulated: true,
        recommendation: item.recommendation,
        indicators: item.indicators,
      );

  factory ScanResultModel.fromPrediction(UrlPrediction prediction) {
    final category = prediction.category;
    final safe = ScanCategory.isSafe(category);
    final runId = prediction.modelRunId;
    return ScanResultModel._(
      id: prediction.scanId,
      url: prediction.url,
      category: category,
      riskLevel: ScanCategory.riskLevel(category),
      confidence: 0,
      isSafe: safe,
      scanTime: formatWib(prediction.createdAt),
      modelName: runId == null
          ? 'SVM + TF-IDF'
          : 'SVM + TF-IDF (${_shortRun(runId)})',
      method: 'Klasifikasi SVM + TF-IDF',
      isSimulated: false,
      recommendation: ScanCategory.recommendation(category),
      indicators: ScanCategory.indicators(category),
      score: prediction.score,
      scoreKind: prediction.scoreKind,
      modelRunId: runId,
    );
  }

  final String id;
  final String url;
  final String category;
  final String riskLevel;
  final int confidence;
  final bool isSafe;
  final String scanTime;
  final String modelName;
  final String method;
  final bool isSimulated;
  final String? recommendation;
  final List<String>? indicators;
  final double? score;
  final String? scoreKind;
  final String? modelRunId;

  ScanResult toEntity() => ScanResult(
    id: id,
    url: url,
    category: category,
    riskLevel: riskLevel,
    confidence: confidence,
    isSafe: isSafe,
    scanTime: scanTime,
    modelName: modelName,
    method: method,
    isSimulated: isSimulated,
    recommendation: recommendation,
    indicators: indicators,
    score: score,
    scoreKind: scoreKind,
    modelRunId: modelRunId,
  );

  static String _shortRun(String id) =>
      id.length <= 8 ? id : id.substring(0, 8);

  /// Formats an API timestamp in Indonesian time.
  static String formatWib(DateTime? value) {
    if (value == null) return '-';
    final wib = value.toUtc().add(const Duration(hours: 7));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = wib.hour.toString().padLeft(2, '0');
    final minute = wib.minute.toString().padLeft(2, '0');
    return '${wib.day} ${months[wib.month - 1]} ${wib.year}, $hour:$minute WIB';
  }
}
