import '../entities/history_entry.dart';

/// Applies the category filter used by the history list.
class FilterHistoryEntries {
  const FilterHistoryEntries();

  /// Filter value that keeps every entry.
  static const allLabel = 'Semua';

  /// Filter options: the neutral option followed by every category in order.
  List<String> categoriesOf(Iterable<HistoryEntry> entries) => [
    allLabel,
    ...entries.map((entry) => entry.category).toSet(),
  ];

  List<HistoryEntry> call(
    Iterable<HistoryEntry> entries, {
    required String filter,
    String query = '',
    String scope = 'Semua',
  }) {
    final term = query.trim().toLowerCase();
    return List.unmodifiable(
      entries.where(
        (entry) =>
            (filter == allLabel || entry.category == filter) &&
            (scope == 'Semua' ||
                (scope == 'Aman' ? entry.isSafe : !entry.isSafe)) &&
            (term.isEmpty || entry.url.toLowerCase().contains(term)),
      ),
    );
  }
}
