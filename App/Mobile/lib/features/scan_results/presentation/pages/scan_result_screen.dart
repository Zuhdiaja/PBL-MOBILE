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
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final summary = widget.controller.summary;
      return ScanSubpage(
        title: 'Hasil scan',
        onNavigate: widget.onNavigate,
        selectedIndex: 2,
        children: [
          const PreviewBadge('HASIL SIMULASI'),
          const SizedBox(height: 16),
          ScanSummaryCard(summary: summary),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ScanStatPill(
                label: '${summary.safeCount} aman',
                color: AppColors.success,
                background: AppColors.paleSuccess,
              ),
              ScanStatPill(
                label: '${summary.attentionCount} perlu perhatian',
                color: AppColors.danger,
                background: AppColors.paleDanger,
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final result in widget.controller.results) ...[
            ScanResultCard(
              result: result,
              onTap: () => widget.onOpenDetail(result),
            ),
            const SizedBox(height: 12),
          ],
        ],
      );
    },
  );
}
