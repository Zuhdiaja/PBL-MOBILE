import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/scan_preview.dart';

Future<void> showScanPreview(
  BuildContext context,
  ScanPreview preview, {
  required VoidCallback onViewResults,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pratinjau pemeriksaan', style: sectionTitleStyle),
            const SizedBox(height: 8),
            const Text(
              'Tautan siap diperiksa. Belum ada penilaian keamanan pada pratinjau ini.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),
            for (final url in preview.urls)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.link, size: 21, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        url.value,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            ScanButton(
              label: 'Lihat Hasil Scan',
              icon: Icons.shield_outlined,
              onPressed: () {
                Navigator.of(context).pop();
                onViewResults();
              },
            ),
            const SizedBox(height: 8),
            ScanButton(
              label: 'Kembali',
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}
