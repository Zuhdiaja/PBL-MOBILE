import '../../../../data/scans_api.dart';
import '../../domain/entities/history_failure.dart';
import '../../domain/entities/history_entry.dart';
import '../../domain/entities/history_page.dart';
import '../models/history_entry_model.dart';
import 'history_data_source.dart';

/// Reads the signed-in user's scans from `/api/v1/mobile/scans`.
class RemoteHistoryDataSource implements HistoryDataSource {
  const RemoteHistoryDataSource(this._api);

  final ScansApi _api;

  Future<HistoryPage<HistoryEntry>> readPage(
    int page,
    HistoryQuery query,
  ) async {
    try {
      final result = await _api.list(
        page: page,
        search: query.search,
        category: query.category,
        scope: query.scope,
      );
      return (
        items: [
          for (final row in result.items)
            HistoryEntryModel.fromScan(row).toEntity(),
        ],
        page: result.page,
        pageCount: result.pageCount,
        total: result.rowCount,
      );
    } on ScansApiException catch (failure) {
      throw HistoryFailure(failure.message);
    }
  }

  @override
  Future<List<HistoryEntryModel>> readEntries() async {
    try {
      final records = await _api.listAll();
      return [for (final record in records) HistoryEntryModel.fromScan(record)];
    } on ScansApiException catch (failure) {
      throw HistoryFailure(failure.message);
    }
  }
}
