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
      return ScanSubpage(
        title: 'Hasil pindai',
        onNavigate: widget.onNavigate,
        selectedIndex: 2,
        children: [
          ScanSummaryCard(summary: summary),
          if (widget.controller.results.isEmpty)
            const InfoNote('Belum ada hasil pindai.'),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (final result in widget.controller.results)
                  ScanResultCard(
                    result: result,
                    onTap: () => widget.onOpenDetail(result),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ScanButton(
            label: 'Periksa URL lain',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 18),
          const InfoNote(
            'Hasil simulasi dari data contoh, bukan penilaian tautan yang Anda masukkan.',
          ),
        ],
      );
    },
  );
}
