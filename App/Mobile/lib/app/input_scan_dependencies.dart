import '../features/input_scan/data/datasources/clipboard_data_source.dart';
import '../features/input_scan/data/datasources/demo_input_scan_examples.dart';
import '../features/input_scan/data/datasources/demo_recent_scans_data_source.dart';
import '../features/input_scan/data/datasources/plugin_share_intent_source.dart';
import '../features/input_scan/data/repositories/clipboard_repository_impl.dart';
import '../features/input_scan/data/repositories/recent_scans_repository_impl.dart';
import '../features/input_scan/domain/repositories/share_intent_source.dart';
import '../features/input_scan/domain/usecases/extract_shared_url.dart';
import '../features/input_scan/domain/usecases/prepare_scan_preview.dart';
import '../features/input_scan/presentation/controllers/home_controller.dart';
import '../features/input_scan/presentation/controllers/scan_qr_controller.dart';
import '../features/input_scan/presentation/controllers/scan_url_controller.dart';
import '../features/input_scan/presentation/controllers/share_link_controller.dart';

/// Composition root: keeps concrete/legacy data out of feature widgets.
class InputScanDependencies {
  InputScanDependencies({ShareIntentSource? shareIntent})
    : shareIntent = shareIntent ?? PluginShareIntentSource() {
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
    _clipboard = clipboard;
    _preparePreview = preparePreview;
    _examples = examples;
  }

  final _recentScans = DemoRecentScansDataSource();
  late final ClipboardRepositoryImpl _clipboard;
  late final PrepareScanPreview _preparePreview;
  late final DemoInputScanExamples _examples;

  /// Text handed over by the operating system share sheet.
  final ShareIntentSource shareIntent;

  /// Picks the URL out of the shared text.
  final ExtractSharedUrl extractSharedUrl = const ExtractSharedUrl();

  late final HomeController home;
  late final ScanUrlController scanUrl;
  late final ScanQrController scanQr;

  /// Creates the share form, optionally filled with an incoming URL.
  ShareLinkController createShareLink({String? initialUrl}) {
    final controller = ShareLinkController(
      clipboardRepository: _clipboard,
      prepareScanPreview: _preparePreview,
      exampleUrl: _examples.sharedUrl,
    );
    if (initialUrl != null && initialUrl.isNotEmpty) {
      controller.prefill(initialUrl);
    }
    return controller;
  }

  void dispose() {
    home.dispose();
    scanUrl.dispose();
    shareIntent.dispose();
  }
}
