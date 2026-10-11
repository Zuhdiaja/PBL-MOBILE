import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/demo_history_data_source.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  const HistoryRepositoryImpl(this._dataSource);

  final DemoHistoryDataSource _dataSource;

  @override
  List<HistoryEntry> getEntries() => List.unmodifiable(
    _dataSource.readEntries().map((model) => model.toEntity()),
  );
}
