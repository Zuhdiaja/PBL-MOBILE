import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_data_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._dataSource);

  final HistoryDataSource _dataSource;

  @override
  Future<List<HistoryEntry>> getEntries() async => List.unmodifiable(
    (await _dataSource.readEntries()).map((model) => model.toEntity()),
  );
}
