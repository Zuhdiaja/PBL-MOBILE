import '../entities/history_entry.dart';

/// Read access to the scan history list.
abstract class HistoryRepository {
  List<HistoryEntry> getEntries();
}
