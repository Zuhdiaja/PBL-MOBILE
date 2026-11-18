import 'package:flutter/material.dart';

import '../../../../widgets/scan_components.dart';
import '../../domain/usecases/prepare_scan_preview.dart';
import '../../domain/usecases/submit_scan.dart';
import '../controllers/scan_qr_controller.dart';
import '../controllers/scan_submission_controller.dart';
import '../widgets/qr_camera_view.dart';
import '../widgets/scan_confirm_dialog.dart';
import '../widgets/scan_preview_sheet.dart';

/// Builds the camera area. Tests pass a fake so no camera is needed.
typedef QrCameraBuilder = Widget Function(
  BuildContext context, {
  required ValueChanged<String> onDetect,
  required bool active,
});

Widget _defaultCamera(
  BuildContext context, {
  required ValueChanged<String> onDetect,
  required bool active,
}) => QrCameraView(onDetect: onDetect, active: active);

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({
    super.key,
    required this.controller,
    required this.submissionController,
    required this.onNavigate,
    required this.onSubmitted,
    this.cameraBuilder = _defaultCamera,
  });

  final ScanQrController controller;
  final ScanSubmissionController submissionController;
  final ValueChanged<ScanSubmission> onSubmitted;
  final ValueChanged<int> onNavigate;
  final QrCameraBuilder cameraBuilder;

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  /// True while the confirmation or the check runs, so one code cannot start
  /// several submissions.
  bool _handling = false;
  String? _shownMessage;

  Future<void> _runScan(PreviewResult result) async {
    if (_handling) return;
    if (result.failure != null) {
      showScanMessage(context, result.failure!.message);
      return;
    }
    setState(() => _handling = true);
    try {
      final confirmed = await showScanConfirmDialog(context, result.preview!);
      if (!mounted || !confirmed) return;
      final submission = await showScanPreview(
        context,
        result.preview!,
        controller: widget.submissionController,
      );
      if (!mounted || submission == null) return;
      widget.onSubmitted(submission);
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  void _handleDetected(String raw) {
    if (!mounted || _handling || ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final result = widget.controller.handleDetected(raw);
    if (result == null) {
      final message = widget.controller.rejection;
      if (message != null && message != _shownMessage) {
        _shownMessage = message;
        showScanMessage(context, message);
      }
      return;
    }
    _shownMessage = null;
    _runScan(result);
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => ScanSubpage(
      title: 'Pindai kode QR',
      onNavigate: widget.onNavigate,
      children: [
        const Text(
          'Arahkan kamera ke QR Code berisi URL. Periksa tautannya sebelum dibuka.',
          style: bodyStyle,
        ),
        const SizedBox(height: 24),
        Semantics(
          label: _handling
              ? 'Kamera dijeda saat tautan diperiksa.'
              : 'Pratinjau kamera untuk memindai QR Code.',
          image: true,
          child: ExcludeSemantics(
            child: widget.cameraBuilder(
              context,
              onDetect: _handleDetected,
              active: ModalRoute.isCurrentOf(context) != false && !_handling,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            _handling
                ? 'Konfirmasi tautan untuk melanjutkan.'
                : 'Tempatkan kode QR di dalam bingkai.',
            textAlign: TextAlign.center,
            style: bodyStyle,
          ),
        ),
        const SizedBox(height: 24),
        ScanButton(
          label: 'Pindai contoh QR',
          onPressed: _handling
              ? null
              : () => _runScan(widget.controller.prepareExamplePreview()),
        ),
        const SizedBox(height: 18),
        const InfoNote(
          'Hanya QR berisi tautan http atau https yang dapat diperiksa.',
        ),
      ],
    ),
  );
}
