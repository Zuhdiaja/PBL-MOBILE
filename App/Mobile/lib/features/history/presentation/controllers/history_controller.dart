import 'package:flutter/foundation.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/filter_history_entries.dart';

/// State for the scan history list and its category filter.
class HistoryController extends ChangeNotifier {
  HistoryController({
    required this.repository,
    required this.filterHistoryEntries,
  });

  final HistoryRepository repository;
  final FilterHistoryEntries filterHistoryEntries;

  List<HistoryEntry> _entries = const [];
  String _filter = FilterHistoryEntries.allLabel;

  List<HistoryEntry> get entries => _entries;
  List<String> get filters => filterHistoryEntries.categoriesOf(_entries);
  String get filter => _filter;
  List<HistoryEntry> get visibleEntries =>
      filterHistoryEntries(_entries, filter: _filter);

  void load() {
    _entries = repository.getEntries();
    notifyListeners();
  }

  void selectFilter(String value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }
}
