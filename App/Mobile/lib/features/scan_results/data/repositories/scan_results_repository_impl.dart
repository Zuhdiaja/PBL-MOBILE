import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_results_repository.dart';
import '../datasources/scan_results_data_source.dart';

class ScanResultsRepositoryImpl implements ScanResultsRepository {
  const ScanResultsRepositoryImpl(this._dataSource);

  final ScanResultsDataSource _dataSource;

  @override
  List<ScanResult> getScanResults() => List.unmodifiable(
    _dataSource.readResults().map((model) => model.toEntity()),
  );

  @override
  ScanResult findById(String id) => _dataSource.readResult(id).toEntity();
}
