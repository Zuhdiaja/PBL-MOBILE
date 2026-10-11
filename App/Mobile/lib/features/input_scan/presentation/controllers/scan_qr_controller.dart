import '../../domain/usecases/prepare_scan_preview.dart';

class ScanQrController {
  const ScanQrController({
    required this.prepareScanPreview,
    required this.exampleUrl,
  });

  final PrepareScanPreview prepareScanPreview;
  final String exampleUrl;

  PreviewResult prepareExamplePreview() => prepareScanPreview([exampleUrl]);
}
