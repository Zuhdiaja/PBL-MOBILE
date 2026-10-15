import 'dart:async';

import '../entities/history_entry.dart';

/// Read access to the scan history list.
abstract class HistoryRepository {
  FutureOr<List<HistoryEntry>> getEntries();
}
