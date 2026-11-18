import 'package:flutter/foundation.dart';

import '../../domain/entities/scan_failure.dart';
import '../../domain/repositories/url_predictor.dart';
import '../../domain/usecases/submit_scan.dart';

/// Where the current submission is in its lifecycle.
enum ScanSubmissionStage { idle, running, done, failed }

/// Drives one submission and exposes its progress to the processing screen.
class ScanSubmissionController extends ChangeNotifier {
  ScanSubmissionController({required this.submitScan, required this.predictor});

  final SubmitScan submitScan;
  final UrlPredictor predictor;

  ScanSubmissionStage _stage = ScanSubmissionStage.idle;
  int _done = 0;
  int _total = 0;
  String? _error;
  ScanSubmission? _submission;
  bool _cancelled = false;
  bool _disposed = false;

  ScanSubmissionStage get stage => _stage;

  /// URLs finished so far.
  int get done => _done;
  int get total => _total;
  String? get error => _error;
  ScanSubmission? get submission => _submission;
  bool get isRunning => _stage == ScanSubmissionStage.running;

  /// Checks every URL and returns the outcome, or null when the run failed or
  /// was cancelled.
  Future<ScanSubmission?> submit(List<String> urls) async {
    if (isRunning || _disposed) return null;
    _stage = ScanSubmissionStage.running;
    _done = 0;
    _total = urls.length;
    _error = null;
    _submission = null;
    _cancelled = false;
    notifyListeners();

    try {
      final result = await submitScan(
        urls,
        predictor,
        onProgress: (done, total) {
          if (_disposed) return;
          _done = done;
          _total = total;
          notifyListeners();
        },
        isCancelled: () => _cancelled || _disposed,
      );
      if (_disposed) return null;
      _submission = result;
      _stage = ScanSubmissionStage.done;
      return result;
    } on ScanFailure catch (failure) {
      if (_disposed) return null;
      _error = failure.message;
      _stage = ScanSubmissionStage.failed;
      return null;
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  /// Stops after the URL currently in flight.
  void cancel() {
    _cancelled = true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
