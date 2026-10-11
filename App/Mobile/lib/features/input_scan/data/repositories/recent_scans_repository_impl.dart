import '../../domain/entities/recent_scan.dart';
import '../../domain/repositories/recent_scans_repository.dart';
import '../datasources/demo_recent_scans_data_source.dart';

class RecentScansRepositoryImpl implements RecentScansRepository {
  const RecentScansRepositoryImpl(this._dataSource);

  final DemoRecentScansDataSource _dataSource;

  @override
  List<RecentScan> getRecentScans() => List.unmodifiable(
    _dataSource.readScans().map((model) => model.toEntity()),
  );
}
