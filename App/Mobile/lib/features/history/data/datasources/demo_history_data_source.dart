import '../../../../data/scan_result.dart';
import '../models/history_entry_model.dart';
import 'history_data_source.dart';

/// Adapter for the example scan history owned by the legacy results data.
///
/// The legacy model and its dummy list stay untouched so the other migrated
/// features keep reading the same source.
class DemoHistoryDataSource implements HistoryDataSource {
  @override
  List<HistoryEntryModel> readEntries() => [
    for (var i = 0; i < demoScanResults.length; i++)
      HistoryEntryModel.fromLegacy('$i', demoScanResults[i]),
  ];
}
