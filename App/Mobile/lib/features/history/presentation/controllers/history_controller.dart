import 'dart:async';

import '../../../scan_results/domain/entities/scan_category.dart';
import '../../domain/entities/history_page.dart';
import 'paged_history_controller.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/usecases/filter_history_entries.dart';

/// State for the scan history list and its category filter.
class HistoryController extends PagedHistoryController<HistoryEntry> {
  HistoryController({
    required this.repository,
    required this.filterHistoryEntries,
    this.isSimulated = true,
    this.searchPage,
  }) : super(repository.getEntries, null, (item) => item.id);

  final HistoryRepository repository;
  final FilterHistoryEntries filterHistoryEntries;
  final Future<HistoryPage<HistoryEntry>> Function(int, HistoryQuery)?
  searchPage;
  Timer? _searchTimer;

  /// True while the list comes from example data instead of the API.
  final bool isSimulated;

  String _filter = FilterHistoryEntries.allLabel;
  String _query = '';
  String _scope = 'Semua';
  String get query => _query;
  String get scope => _scope;
  bool get isSearchPending => _searchTimer?.isActive ?? false;

  @override
  Future<HistoryPage<HistoryEntry>> readPage(int page) {
    final search = searchPage;
    if (search == null) return super.readPage(page);
    return search(page, (
      search: _query.trim(),
      category: switch (_filter) {
        FilterHistoryEntries.allLabel => null,
        ScanCategory.unknown => 'unknown',
        _ => _filter.toLowerCase(),
      },
      scope: switch (_scope) {
        'Aman' => 'safe',
        'Perlu perhatian' => 'unsafe',
        _ => 'all',
      },
    ));
  }

  void setQuery(String value) {
    if (_query == value) return;
    final changed = _query.trim() != value.trim();
    _query = value;
    if (searchPage != null && changed) {
      _searchTimer?.cancel();
      _searchTimer = Timer(const Duration(milliseconds: 300), _loadSearch);
    }
    notifyListeners();
  }

  void selectScope(String value) {
    if (_scope == value) return;
    _scope = value;
    _loadSearch();
  }

  List<HistoryEntry> get entries => items;
  List<String> get filters => searchPage == null
      ? filterHistoryEntries.categoriesOf(items)
      : const [
          FilterHistoryEntries.allLabel,
          ScanCategory.benign,
          ScanCategory.legitimate,
          ScanCategory.phishing,
          ScanCategory.malware,
          ScanCategory.spam,
          ScanCategory.defacement,
          ScanCategory.exploit,
          ScanCategory.unknown,
        ];
  String get filter => _filter;
  List<HistoryEntry> get visibleEntries => searchPage != null
      ? items
      : filterHistoryEntries(
          items,
          filter: _filter,
          query: _query,
          scope: _scope,
        );
  int get resultCount => searchPage == null ? visibleEntries.length : total;

  void selectFilter(String value) {
    if (_filter == value) return;
    _filter = value;
    _loadSearch();
  }

  void _loadSearch() {
    if (searchPage == null) {
      notifyListeners();
      return;
    }
    _searchTimer?.cancel();
    _searchTimer = null;
    unawaited(load(supersede: true));
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}
