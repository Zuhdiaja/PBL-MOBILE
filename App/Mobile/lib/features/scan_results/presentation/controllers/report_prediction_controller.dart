import 'package:flutter/material.dart';

import '../../domain/entities/prediction_report.dart';
import '../../domain/entities/scan_result.dart';
import '../../domain/repositories/prediction_report_repository.dart';
import '../../domain/usecases/submit_prediction_report.dart';

/// State for the correction form of one prediction.
class ReportPredictionController extends ChangeNotifier {
  ReportPredictionController({
    required this.result,
    required this.repository,
    required this.submitPredictionReport,
  });

  final ScanResult result;
  final PredictionReportRepository repository;
  final SubmitPredictionReport submitPredictionReport;

  ReportType _type = ReportType.falsePositive;
  String _category = '';
  final _notes = TextEditingController();
  bool _isSubmitting = false;
  bool _disposed = false;
  SubmittedPredictionReport? _lastSubmitted;

  ReportType get type => _type;
  String get category => _category;
  TextEditingController get notes => _notes;
  List<String> get categories => repository.getCategories();

  /// True while a submission is in flight; the form must not send twice.
  bool get isSubmitting => _isSubmitting;

  /// Record the API created for the latest accepted correction.
  SubmittedPredictionReport? get lastSubmitted => _lastSubmitted;

  void selectType(ReportType value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }

  void selectCategory(String? value) {
    final next = value ?? '';
    if (_category == next) return;
    _category = next;
    notifyListeners();
  }

  /// Sends the correction and returns the user facing message on failure.
  Future<String?> submit() async {
    if (_isSubmitting) return null;
    _isSubmitting = true;
    notifyListeners();
    try {
      final outcome = await submitPredictionReport(
        PredictionReport(
          url: result.url,
          type: _type,
          category: _category,
          notes: _notes.text,
        ),
        repository,
      );
      if (_disposed) return null;
      _lastSubmitted = outcome.report;
      return outcome.failure?.message;
    } finally {
      _isSubmitting = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _notes.dispose();
    super.dispose();
  }
}
