import '../../../../data/scan_result.dart';
import '../../domain/entities/history_entry.dart';

/// Maps the legacy result model onto the history entity.
class HistoryEntryModel {
  const HistoryEntryModel({required this.id, required this.item});

  final String id;
  final ScanResultItem item;

  HistoryEntry toEntity() => HistoryEntry(
    id: id,
    url: item.url,
    category: item.category,
    confidence: item.confidence,
    isSafe: item.isSafe,
    scanTime: item.scanTime,
    dayLabel: item.dayLabel,
  );
}
