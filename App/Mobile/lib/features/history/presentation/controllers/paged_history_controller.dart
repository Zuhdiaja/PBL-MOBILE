import 'dart:async';

import '../../../../presentation/load_controller.dart';
import '../../domain/entities/history_failure.dart';
import '../../domain/entities/history_page.dart';

abstract class PagedHistoryController<T> extends LoadController {
  PagedHistoryController(this._readAll, this._readPage, this._key);

  final FutureOr<List<T>> Function() _readAll;
  final Future<HistoryPage<T>> Function(int)? _readPage;
  final String Function(T) _key;
  HistoryPage<T>? _page;
  bool _disposed = false;
  int _revision = 0;
  bool isLoadingMore = false;
  String? loadMoreError;

  List<T> get items => _page?.items ?? [];
  int get total => _page?.total ?? 0;
  bool get hasMore => switch (_page) {
    final page? => page.page < page.pageCount,
    null => false,
  };

  Future<HistoryPage<T>> readPage(int page) async {
    if (_readPage case final read?) return read(page);
    final items = await _readAll();
    return (items: items, page: 1, pageCount: 1, total: items.length);
  }

  void _replace(HistoryPage<T> result) {
    _page = result;
    loadMoreError = null;
  }

  @override
  Future<void> load({bool supersede = false}) {
    if (supersede) {
      _revision++;
      isLoadingMore = false;
      loadMoreError = null;
    }
    return loadValue(
      () => readPage(1),
      _replace,
      describeError: (error) => error is HistoryFailure ? error.message : null,
      supersede: supersede,
    );
  }

  Future<void> refresh() => refreshValue(() => readPage(1), _replace);

  Future<void> loadMore() async {
    final current = _page;
    if (_disposed ||
        isLoading ||
        isLoadingMore ||
        current == null ||
        !hasMore) {
      return;
    }
    final revision = _revision;
    isLoadingMore = true;
    loadMoreError = null;
    notifyListeners();
    await refreshValue(
      () async {
        try {
          return await readPage(current.page + 1);
        } catch (error) {
          if (!_disposed && revision == _revision) {
            loadMoreError = error is HistoryFailure
                ? error.message
                : 'Halaman berikutnya belum dapat dimuat.';
          }
          rethrow;
        }
      },
      (result) {
        final seen = current.items.map(_key).toSet();
        _replace((
          items: [
            ...current.items,
            ...result.items.where((item) => seen.add(_key(item))),
          ],
          page: result.page,
          pageCount: result.pageCount,
          total: result.total,
        ));
      },
    );
    if (_disposed || revision != _revision) return;
    isLoadingMore = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
