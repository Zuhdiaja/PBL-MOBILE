import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
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
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.flag_outlined,
              color: AppColors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${report.type} · ${report.submittedTime}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                    height: 1.4,
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

  Color get _color => switch (stage) {
    ReportStage.completed => AppColors.success,
    ReportStage.review => AppColors.warning,
    ReportStage.submitted => AppColors.blue,
  };

  Color get _background => switch (stage) {
    ReportStage.completed => AppColors.paleSuccess,
    ReportStage.review => AppColors.paleWarning,
    ReportStage.submitted => AppColors.paleBlue,
  };

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: _background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      stage.label,
      style: TextStyle(
        color: _color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ReportMetaRow extends StatelessWidget {
  const ReportMetaRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
  final bool done;
  final bool isLast;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      children: [
        Column(
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: done ? AppColors.success : AppColors.muted,
              size: 19,
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  color: done ? AppColors.success : AppColors.line,
                ),
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              label,
              style: TextStyle(
                color: done ? AppColors.ink : AppColors.muted,
                fontSize: 13,
                fontWeight: done ? FontWeight.w700 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
