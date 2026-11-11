import '../../domain/entities/report_status.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../datasources/report_status_data_source.dart';

class ReportStatusRepositoryImpl implements ReportStatusRepository {
  const ReportStatusRepositoryImpl(this._dataSource);

  final ReportStatusDataSource _dataSource;

  @override
  Future<List<ReportStatus>> getReports() async => List.unmodifiable(
    (await _dataSource.readReports()).map((model) => model.toEntity()),
  );
}
