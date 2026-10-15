import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/report_status.dart';

class ReportStatusCard extends StatelessWidget {
  const ReportStatusCard({
    super.key,
    required this.report,
    required this.onTap,
  });
  final ReportStatus report;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.description_outlined,
            color: context.colors.muted,
            size: 19,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayHost(report.url),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${report.type == 'False Positive' ? 'Positif palsu' : 'Negatif palsu'} · ${report.submittedTime}',
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.muted,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ReportStatusBadge(stage: report.stage),
        ],
      ),
    ),
  );
}

class ReportStatusBadge extends StatelessWidget {
  const ReportStatusBadge({super.key, required this.stage});
  final ReportStage stage;
  @override
  Widget build(BuildContext context) {
    final color = switch (stage) {
      ReportStage.completed => context.colors.success,
      ReportStage.review => context.colors.blue,
      ReportStage.submitted => context.colors.warning,
    };
    final bg = switch (stage) {
      ReportStage.completed => context.colors.paleSuccess,
      ReportStage.review => context.colors.paleBlue,
      ReportStage.submitted => context.colors.paleWarning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        stage == ReportStage.submitted ? 'Menunggu' : stage.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class ReportMetaRow extends StatelessWidget {
  const ReportMetaRow({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: context.colors.muted),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}

class ReportTimelineStep extends StatelessWidget {
  const ReportTimelineStep({
    super.key,
    required this.label,
    required this.done,
    required this.isLast,
  });
  final String label;
  final bool done, isLast;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Icon(
          done
              ? Icons.check_circle_outline_rounded
              : Icons.radio_button_unchecked_rounded,
          color: done ? context.colors.success : context.colors.muted,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: done ? context.colors.ink : context.colors.muted,
            ),
          ),
        ),
      ],
    ),
  );
}
