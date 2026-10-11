import '../../../../data/scan_result.dart';
import '../../domain/entities/scan_result.dart';

/// Maps the legacy result model onto the domain entity.
class ScanResultModel {
  const ScanResultModel({required this.id, required this.item});

  final String id;
  final ScanResultItem item;

  ScanResult toEntity() => ScanResult(
    id: id,
    url: item.url,
    category: item.category,
    riskLevel: item.riskLevel,
    confidence: item.confidence,
    isSafe: item.isSafe,
    scanTime: item.scanTime,
    modelName: item.modelName,
    method: item.method,
    recommendation: item.recommendation,
    indicators: item.indicators,
  );
}
