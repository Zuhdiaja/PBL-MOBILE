import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../theme/app_colors.dart';

/// Live camera preview for QR codes.
///
/// This widget is the only place that talks to the scanner plugin; the screen
/// and controller stay free of it so they can be tested without a camera.
class QrCameraView extends StatefulWidget {
  const QrCameraView({super.key, required this.onDetect, required this.active});

  /// Called with the raw text of the first readable code.
  final ValueChanged<String> onDetect;

  /// False pauses the camera, e.g. while a scan is being submitted.
  final bool active;

  @override
  State<QrCameraView> createState() => _QrCameraViewState();
}

class _QrCameraViewState extends State<QrCameraView> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void didUpdateWidget(QrCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    // A closed camera also turns the torch off with it.
    _toggleRunning(widget.active);
  }

  Future<void> _toggleRunning(bool running) async {
    try {
      if (running) {
        await _controller.start();
      } else {
        await _controller.stop();
      }
    } catch (_) {
      // The camera may already be stopped by the platform; nothing to recover.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();
      if (value != null && value.isNotEmpty) {
        widget.onDetect(value);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.38,
    child: Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.scanner,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
            errorBuilder: (context, error) => _CameraProblem(error: error),
          ),
          const _ScanFrame(),
          if (!widget.active)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Text(
                  'Kamera dijeda',
                  style: TextStyle(
                    color: context.colors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            right: 10,
            bottom: 10,
            child: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                if (state.torchState == TorchState.unavailable) {
                  return const SizedBox.shrink();
                }
                final on = state.torchState == TorchState.on;
                return IconButton.filledTonal(
                  tooltip: on ? 'Matikan senter' : 'Nyalakan senter',
                  onPressed: () => _controller.toggleTorch(),
                  icon: Icon(
                    on
                        ? Icons.flashlight_on_rounded
                        : Icons.flashlight_off_rounded,
                    size: 20,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

/// Frame drawn over the preview so the user knows where to aim.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight * 0.74;
        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFB2C9F7), width: 3),
            ),
          ),
        );
      },
    ),
  );
}

/// Shown instead of the preview when the camera cannot start.
class _CameraProblem extends StatelessWidget {
  const _CameraProblem({required this.error});

  final MobileScannerException error;

  bool get _denied =>
      error.errorCode == MobileScannerErrorCode.permissionDenied;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _denied
                ? Icons.no_photography_outlined
                : Icons.videocam_off_outlined,
            color: context.colors.muted,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            _denied ? 'Izin kamera ditolak' : 'Kamera tidak dapat digunakan',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _denied
                ? 'Aktifkan izin kamera untuk LinkGuard di Pengaturan Android, lalu buka kembali layar ini.'
                : 'Perangkat ini tidak menyediakan kamera. Gunakan tautan contoh di bawah.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.colors.muted,
              fontSize: 11,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
  );
}
