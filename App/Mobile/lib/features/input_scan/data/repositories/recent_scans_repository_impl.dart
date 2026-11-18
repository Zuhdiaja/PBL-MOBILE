import '../../domain/entities/recent_scan.dart';
import '../../domain/repositories/recent_scans_repository.dart';
import '../datasources/recent_scans_data_source.dart';

class RecentScansRepositoryImpl implements RecentScansRepository {
  const RecentScansRepositoryImpl(this._dataSource);

  final RecentScansDataSource _dataSource;

  @override
  Future<List<RecentScan>> getRecentScans() async => List.unmodifiable(
    (await _dataSource.readScans()).map((model) => model.toEntity()),
  );
}
