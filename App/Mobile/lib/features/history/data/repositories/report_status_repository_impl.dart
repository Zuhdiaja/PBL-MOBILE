import '../../domain/entities/report_status.dart';
import '../../domain/repositories/report_status_repository.dart';
import '../datasources/demo_report_status_data_source.dart';

class ReportStatusRepositoryImpl implements ReportStatusRepository {
  const ReportStatusRepositoryImpl(this._dataSource);

  final DemoReportStatusDataSource _dataSource;

  @override
  List<ReportStatus> getReports() => List.unmodifiable(
    _dataSource.readReports().map((model) => model.toEntity()),
  );
}
