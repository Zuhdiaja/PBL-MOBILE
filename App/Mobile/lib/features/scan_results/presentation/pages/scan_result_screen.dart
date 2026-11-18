import '../../../../widgets/load_view.dart';

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/scan_result.dart';
import '../controllers/scan_results_controller.dart';
import '../widgets/scan_result_cards.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({
    super.key,
    required this.controller,
    required this.onOpenDetail,
    this.onNavigate,
  });

  final ScanResultsController controller;
  final ValueChanged<ScanResult> onOpenDetail;
  final ValueChanged<int>? onNavigate;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  @override
  Widget build(BuildContext context) => LoadView(
    controller: widget.controller,
    kind: 'results',
    subpage: true,
    builder: (context) {
      final summary = widget.controller.summary;
      final results = widget.controller.results;
      final failures = widget.controller.failures;
      final simulated =
          results.isNotEmpty && results.every((r) => r.isSimulated);
      return ScanSubpage(
        title: 'Hasil pindai',
        onNavigate: widget.onNavigate,
        selectedIndex: 2,
        children: [
          ScanSummaryCard(summary: summary),
          if (results.isEmpty && failures.isEmpty)
            const InfoNote('Belum ada hasil pindai.'),
          const SizedBox(height: 20),
          if (results.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (final result in results)
                    ScanResultCard(
                      result: result,
                      onTap: () => widget.onOpenDetail(result),
                    ),
                ],
              ),
            ),
          if (failures.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text('Belum bisa diperiksa', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              'Tautan berikut gagal diperiksa. Periksa koneksi lalu coba lagi.',
              style: TextStyle(
                fontSize: 12,
                color: context.colors.muted,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (final failure in failures)
                    FailedScanCard(failure: failure),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ScanButton(
            label: 'Periksa URL lain',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          if (simulated)
            const InfoNote(
              'Hasil simulasi dari data contoh, bukan penilaian tautan yang Anda masukkan.',
            )
          else if (results.isNotEmpty)
            const InfoNote(
              'Hasil berasal dari model SVM + TF-IDF. Skor margin bukan probabilitas keamanan.',
            ),
        ],
      );
    },
  );
}
