import '../../../../data/scan_result.dart';
import '../models/history_entry_model.dart';

/// Adapter for the example scan history owned by the legacy results data.
///
/// The legacy model and its dummy list stay untouched so the other migrated
/// features keep reading the same source.
class DemoHistoryDataSource {
  List<HistoryEntryModel> readEntries() => [
    for (var i = 0; i < demoScanResults.length; i++)
      HistoryEntryModel(id: '$i', item: demoScanResults[i]),
  ];
}
