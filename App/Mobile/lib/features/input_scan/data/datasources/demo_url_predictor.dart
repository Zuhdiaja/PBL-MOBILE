import '../../../scan_results/domain/entities/scan_category.dart';
import '../../domain/entities/url_prediction.dart';
import '../../domain/repositories/url_predictor.dart';

/// Offline predictor for previews and widget tests.
///
/// It never reaches the network and stays deterministic: URLs that look like
/// the usual risky patterns are classified as phishing, everything else as
/// benign. The app uses [RemoteUrlPredictor] once a session exists.
class DemoUrlPredictor implements UrlPredictor {
  const DemoUrlPredictor();

  static const _risky = ['login', 'klaim', 'hadiah', 'verifikasi', 'jahat'];

  @override
  Future<UrlPrediction> predict(String url) async {
    final lower = url.toLowerCase();
    final risky = _risky.any(lower.contains);
    return UrlPrediction(
      scanId: 'demo-${lower.hashCode.toUnsigned(20)}',
      url: url,
      category: risky ? ScanCategory.phishing : ScanCategory.benign,
      score: risky ? 1.42 : 1.08,
      scoreKind: 'margin',
      modelRunId: 'demo-run',
      createdAt: DateTime.now().toUtc(),
    );
  }
}
