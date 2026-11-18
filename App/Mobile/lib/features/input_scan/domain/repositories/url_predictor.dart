import '../entities/url_prediction.dart';

/// Checks one URL against the classification service.
///
/// Throws `ScanFailure` with a message fit for the user when the URL cannot be
/// checked.
abstract class UrlPredictor {
  Future<UrlPrediction> predict(String url);
}
