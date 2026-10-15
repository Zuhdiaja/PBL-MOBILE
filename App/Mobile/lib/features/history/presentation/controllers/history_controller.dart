import '../../../../presentation/load_controller.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/filter_history_entries.dart';

/// State for the scan history list and its category filter.
class HistoryController extends LoadController {
  HistoryController({
    required this.repository,
    required this.filterHistoryEntries,
  });

  final HistoryRepository repository;
  final FilterHistoryEntries filterHistoryEntries;

  List<HistoryEntry> _entries = const [];
  String _filter = FilterHistoryEntries.allLabel;
  String _query = '';
  String _scope = 'Semua';
  String get query => _query;
  String get scope => _scope;
  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void selectScope(String value) {
    _scope = value;
    notifyListeners();
  }

  List<HistoryEntry> get entries => _entries;
  List<String> get filters => filterHistoryEntries.categoriesOf(_entries);
  String get filter => _filter;
  List<HistoryEntry> get visibleEntries => filterHistoryEntries(
    _entries,
    filter: _filter,
    query: _query,
    scope: _scope,
  );

  @override
  Future<void> load() {
    return loadValue(repository.getEntries, (value) => _entries = value);
  }

  void selectFilter(String value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }
}
