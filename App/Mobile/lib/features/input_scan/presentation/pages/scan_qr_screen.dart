import 'package:flutter/material.dart';

import '../../../../widgets/scan_components.dart';
import '../../../../theme/app_colors.dart';
import '../controllers/scan_qr_controller.dart';
import '../widgets/scan_preview_sheet.dart';

class ScanQrScreen extends StatelessWidget {
  const ScanQrScreen({
    super.key,
    required this.controller,
    required this.onNavigate,
    required this.onViewResults,
  });

  final ScanQrController controller;
  final VoidCallback onViewResults;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => ScanSubpage(
    title: 'Pindai kode QR',
    onNavigate: onNavigate,
    children: [
      const Text(
        'Arahkan kamera ke QR Code berisi URL. Periksa tautannya sebelum dibuka.',
        style: bodyStyle,
      ),
      const SizedBox(height: 24),
      Semantics(
        label: 'Pratinjau area pemindaian QR Code. Kamera belum terhubung.',
        image: true,
        child: ExcludeSemantics(
          child: AspectRatio(
            aspectRatio: 1.38,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: context.colors.scanner,
                borderRadius: BorderRadius.circular(14),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxHeight * 0.74;
                  return Center(
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18284B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFB2C9F7),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                          Positioned(
                            left: 16,
                            right: 16,
                            child: Container(
                              height: 2,
                              color: const Color(0xFF76A4FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 20),
      const Center(
        child: Text(
          'Tempatkan kode QR di dalam bingkai.',
          textAlign: TextAlign.center,
          style: bodyStyle,
        ),
      ),
      const SizedBox(height: 24),
      ScanButton(
        label: 'Pindai contoh QR',
        onPressed: () {
          final result = controller.prepareExamplePreview();
          if (result.failure != null) {
            showScanMessage(context, result.failure!.message);
            return;
          }
          showScanPreview(
            context,
            result.preview!,
            preparePreview: controller.prepareExamplePreview,
            onViewResults: onViewResults,
          );
        },
      ),
      const SizedBox(height: 18),
      const InfoNote(
        'Kamera belum terhubung. Gunakan contoh QR untuk mencoba alur pemeriksaan.',
      ),
    ],
  );
}
