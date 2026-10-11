import '../entities/input_scan_failure.dart';
import '../entities/scan_preview.dart';
import '../entities/url_input.dart';

typedef PreviewResult = ({ScanPreview? preview, InputScanFailure? failure});

class PrepareScanPreview {
  const PrepareScanPreview();

  static const maxUrls = 5;

  PreviewResult call(Iterable<String> values) {
    final urls = values.map(UrlInput.new).toList();
    if (urls.isEmpty || urls.length > maxUrls) {
      return (
        preview: null,
        failure: const InputScanFailure('Masukkan 1 sampai 5 URL.'),
      );
    }
    for (final url in urls) {
      final message = url.validationMessage;
      if (message != null) {
        return (preview: null, failure: InputScanFailure(message));
      }
    }
    return (preview: ScanPreview(urls), failure: null);
  }
}
