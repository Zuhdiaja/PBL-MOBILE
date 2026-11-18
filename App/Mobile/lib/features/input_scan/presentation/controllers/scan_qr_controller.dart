import 'package:flutter/foundation.dart';

import '../../domain/entities/qr_extraction.dart';
import '../../domain/usecases/extract_qr_url.dart';
import '../../domain/usecases/prepare_scan_preview.dart';

/// State for the QR screen: the example fallback and the camera readings.
///
/// The camera itself lives in the widget layer; this controller only decides
/// whether a reading is a checkable link.
class ScanQrController extends ChangeNotifier {
  ScanQrController({
    required this.prepareScanPreview,
    required this.exampleUrl,
    this.extractQrUrl = const ExtractQrUrl(),
  });

  final PrepareScanPreview prepareScanPreview;
  final String exampleUrl;
  final ExtractQrUrl extractQrUrl;

  /// Last reading that was refused, so a camera pointed at the same code does
  /// not repeat the same message on every frame.
  String? _rejected;

  QrExtraction? _lastExtraction;

  /// Reason the latest reading was refused, or null when it was accepted.
  String? get rejection => _lastExtraction?.message;

  PreviewResult prepareExamplePreview() => prepareScanPreview([exampleUrl]);

  /// Reads one QR payload.
  ///
  /// Returns the preview when the code holds a URL. Returns null when the code
  /// was refused or is a repeat of the previous refusal; [rejection] then says
  /// why.
  PreviewResult? handleDetected(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty && trimmed == _rejected) return null;

    final extraction = extractQrUrl(trimmed);
    _lastExtraction = extraction;
    if (extraction.url == null) {
      _rejected = trimmed;
      notifyListeners();
      return null;
    }

    _rejected = null;
    notifyListeners();
    return prepareScanPreview([extraction.url!]);
  }

  /// Forgets the last refusal so the same code can be tried again.
  void clearRejection() {
    _rejected = null;
    _lastExtraction = null;
    notifyListeners();
  }
}
