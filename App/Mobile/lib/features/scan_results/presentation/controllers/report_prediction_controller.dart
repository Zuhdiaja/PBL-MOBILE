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

  ReportType get type => _type;
  String get category => _category;
  TextEditingController get notes => _notes;
  List<String> get categories => repository.getCategories();

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

  /// Returns the user facing message when submission fails, otherwise null.
  String? submit() => submitPredictionReport(
    PredictionReport(
      url: result.url,
      type: _type,
      category: _category,
      notes: _notes.text,
    ),
    repository,
  ).failure?.message;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }
}
