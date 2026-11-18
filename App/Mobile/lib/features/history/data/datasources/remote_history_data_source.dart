import '../../../../data/scans_api.dart';
import '../../domain/entities/history_failure.dart';
import '../models/history_entry_model.dart';
import 'history_data_source.dart';

/// Reads the signed-in user's scans from `/api/v1/mobile/scans`.
class RemoteHistoryDataSource implements HistoryDataSource {
  const RemoteHistoryDataSource(this._api);

  final ScansApi _api;

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
