import '../../domain/entities/prediction_report.dart';
import '../../domain/repositories/prediction_report_repository.dart';
import '../datasources/demo_prediction_report_data_source.dart';

class PredictionReportRepositoryImpl implements PredictionReportRepository {
  const PredictionReportRepositoryImpl(this._dataSource);

  final DemoPredictionReportDataSource _dataSource;

  @override
  List<String> getCategories() =>
      List.unmodifiable(_dataSource.readCategories());

  @override
  bool submit(PredictionReport report) => _dataSource.write(report);
}
