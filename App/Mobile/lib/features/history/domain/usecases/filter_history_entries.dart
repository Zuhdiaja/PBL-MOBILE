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
  }) => filter == allLabel
      ? List.unmodifiable(entries)
      : List.unmodifiable(entries.where((entry) => entry.category == filter));
}
