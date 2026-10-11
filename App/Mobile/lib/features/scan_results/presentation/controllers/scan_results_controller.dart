import 'package:flutter/material.dart';

import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/scan_results_repository.dart';
import '../../domain/usecases/summarize_scan_results.dart';

/// State for the list of results and the counts above it.
class ScanResultsController extends ChangeNotifier {
  ScanResultsController({
    required this.repository,
    required this.summarizeScanResults,
  });

  final ScanResultsRepository repository;
  final SummarizeScanResults summarizeScanResults;

  List<ScanResult> _results = const [];
  ScanResultSummary _summary = const ScanResultSummary(
    totalCount: 0,
    safeCount: 0,
    attentionCount: 0,
  );

  List<ScanResult> get results => List.unmodifiable(_results);
  ScanResultSummary get summary => _summary;

  void load() {
    final loaded = repository.getScanResults();
    _results = loaded;
    _summary = summarizeScanResults(loaded);
    notifyListeners();
  }
}
