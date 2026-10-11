import '../features/input_scan/data/datasources/clipboard_data_source.dart';
import '../features/input_scan/data/datasources/demo_input_scan_examples.dart';
import '../features/input_scan/data/datasources/demo_recent_scans_data_source.dart';
import '../features/input_scan/data/repositories/clipboard_repository_impl.dart';
import '../features/input_scan/data/repositories/recent_scans_repository_impl.dart';
import '../features/input_scan/domain/entities/recent_scan.dart';
import '../features/input_scan/domain/usecases/prepare_scan_preview.dart';
import '../features/input_scan/presentation/controllers/home_controller.dart';
import '../features/input_scan/presentation/controllers/scan_qr_controller.dart';
import '../features/input_scan/presentation/controllers/scan_url_controller.dart';
import '../features/input_scan/presentation/controllers/share_link_controller.dart';
import '../screens/scan_detail_screen.dart';

/// Composition root: keeps concrete/legacy data out of feature widgets.
class InputScanDependencies {
  InputScanDependencies() {
    final clipboard = ClipboardRepositoryImpl(
      const SystemClipboardDataSource(),
    );
    const preparePreview = PrepareScanPreview();
    const examples = DemoInputScanExamples();
    home = HomeController(RecentScansRepositoryImpl(_recentScans));
    scanUrl = ScanUrlController(
      clipboardRepository: clipboard,
      prepareScanPreview: preparePreview,
    );
    scanQr = ScanQrController(
      prepareScanPreview: preparePreview,
      exampleUrl: examples.qrUrl,
    );
    createShareLink = () => ShareLinkController(
      clipboardRepository: clipboard,
      prepareScanPreview: preparePreview,
      exampleUrl: examples.sharedUrl,
    );
  }

  final _recentScans = DemoRecentScansDataSource();
  late final HomeController home;
  late final ScanUrlController scanUrl;
  late final ScanQrController scanQr;
  late final ShareLinkController Function() createShareLink;

  ScanDetailScreen detailFor(RecentScan scan) =>
      ScanDetailScreen(item: _recentScans.resolveDetail(scan.id));

  void dispose() => scanUrl.dispose();
}
