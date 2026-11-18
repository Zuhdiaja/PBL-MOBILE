import 'dart:async';

import '../models/history_entry_model.dart';

/// Source of the scan history list.
abstract class HistoryDataSource {
  FutureOr<List<HistoryEntryModel>> readEntries();
}
