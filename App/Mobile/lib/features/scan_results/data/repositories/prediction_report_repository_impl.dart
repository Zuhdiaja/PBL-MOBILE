import '../../domain/entities/prediction_report.dart';
import '../../domain/repositories/prediction_report_repository.dart';
import '../datasources/prediction_report_data_source.dart';

class PredictionReportRepositoryImpl implements PredictionReportRepository {
  const PredictionReportRepositoryImpl(this._dataSource);

  final PredictionReportDataSource _dataSource;

  @override
  List<String> getCategories() =>
      List.unmodifiable(_dataSource.readCategories());

  @override
  Future<SubmittedPredictionReport> submit(PredictionReport report) async =>
      (await _dataSource.write(report)).toEntity();
}
