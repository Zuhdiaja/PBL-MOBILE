import '../../../../data/scans_api.dart';
import '../../domain/entities/input_scan_failure.dart';
import '../models/recent_scan_model.dart';
import 'recent_scans_data_source.dart';

/// Reads the newest scans of the signed-in user from the API.
class RemoteRecentScansDataSource implements RecentScansDataSource {
  const RemoteRecentScansDataSource(this._api);

  final ScansApi _api;

  /// The home screen only shows a short list.
  static const limit = 3;

  @override
  Future<List<RecentScanModel>> readScans() async {
    try {
      final page = await _api.list();
      return [
        for (final record in page.items.take(limit))
          RecentScanModel.fromScan(record),
      ];
    } on ScansApiException catch (failure) {
      throw InputScanFailure(failure.message);
    }
  }
}
