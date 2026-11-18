import '../../../../data/scan_result.dart';
import '../../../../data/scan_time.dart';
import '../../../../data/scans_api.dart';
import '../../domain/entities/history_entry.dart';

/// Maps both the legacy example data and a stored scan onto the history entity.
class HistoryEntryModel {
  const HistoryEntryModel._({
    required this.id,
    required this.url,
    required this.category,
    required this.isSafe,
    required this.scanTime,
    required this.dayLabel,
    this.confidence = 0,
    this.score,
    this.scoreKind,
  });

  factory HistoryEntryModel.fromLegacy(String id, ScanResultItem item) =>
      HistoryEntryModel._(
        id: id,
        url: item.url,
        category: item.category,
        isSafe: item.isSafe,
        scanTime: item.scanTime,
        dayLabel: item.dayLabel,
        confidence: item.confidence,
      );

  factory HistoryEntryModel.fromScan(ScanRecord record) => HistoryEntryModel._(
    id: record.id,
    url: record.url,
    category: record.category,
    isSafe: record.isSafe,
    scanTime: ScanTime.stamp(record.createdAt),
    dayLabel: ScanTime.dayLabel(record.createdAt),
    score: record.score,
    scoreKind: record.scoreKind,
  );

  final String id;
  final String url;
  final String category;
  final bool isSafe;
  final String scanTime;
  final String dayLabel;
  final int confidence;
  final double? score;
  final String? scoreKind;

  HistoryEntry toEntity() => HistoryEntry(
    id: id,
    url: url,
    category: category,
    confidence: confidence,
    isSafe: isSafe,
    scanTime: scanTime,
    dayLabel: dayLabel,
    score: score,
    scoreKind: scoreKind,
  );
}
