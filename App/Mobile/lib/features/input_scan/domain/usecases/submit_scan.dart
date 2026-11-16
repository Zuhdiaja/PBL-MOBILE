import '../entities/scan_failure.dart';
import '../entities/url_prediction.dart';
import '../repositories/url_predictor.dart';

/// Outcome of checking one URL: either a prediction or a failure.
typedef ScanAttempt = ({
  String url,
  UrlPrediction? prediction,
  ScanFailure? failure,
});

/// Every URL of one submission, including the ones that failed.
typedef ScanSubmission = ({
  List<ScanAttempt> attempts,
  int succeeded,
  int failed,
});

/// Called after each URL finishes, with the number done and the total.
typedef ScanProgress = void Function(int done, int total);

/// Checks each URL in turn.
///
/// A URL that fails does not stop the others: the user still gets the results
/// that did work, and the failed ones are marked. Only an expired session is
/// fatal, because every remaining request would fail the same way.
class SubmitScan {
  const SubmitScan();

  Future<ScanSubmission> call(
    List<String> urls,
    UrlPredictor predictor, {
    ScanProgress? onProgress,
    bool Function()? isCancelled,
  }) async {
    final attempts = <ScanAttempt>[];
    var succeeded = 0;
    var failed = 0;

    for (var index = 0; index < urls.length; index++) {
      if (isCancelled?.call() ?? false) break;
      final url = urls[index];
      try {
        final prediction = await predictor.predict(url);
        attempts.add((url: url, prediction: prediction, failure: null));
        succeeded++;
      } on ScanFailure catch (failure) {
        if (failure.isFatal) {
          onProgress?.call(index + 1, urls.length);
          rethrow;
        }
        attempts.add((url: url, prediction: null, failure: failure));
        failed++;
      }
      onProgress?.call(index + 1, urls.length);
    }

    final ScanSubmission submission = (
      attempts: List<ScanAttempt>.unmodifiable(attempts),
      succeeded: succeeded,
      failed: failed,
    );
    return submission;
  }
}
