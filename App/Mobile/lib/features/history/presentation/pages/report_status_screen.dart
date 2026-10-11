import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/scan_components.dart';
import '../../domain/entities/report_status.dart';
import '../../domain/usecases/build_report_timeline.dart';
import '../controllers/report_status_controller.dart';
import '../widgets/report_status_widgets.dart';

class ReportStatusScreen extends StatefulWidget {
  const ReportStatusScreen({super.key, required this.controller});

  final ReportStatusController controller;

  @override
  State<ReportStatusScreen> createState() => _ReportStatusScreenState();
}

class _ReportStatusScreenState extends State<ReportStatusScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  void _openDetail(ReportStatus report) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReportDetailScreen(
        report: report,
        buildReportTimeline: widget.controller.buildReportTimeline,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) => ScanSubpage(
      title: 'Status laporan',
      selectedIndex: 4,
      children: [
        Text(
          '${widget.controller.reports.length} laporan pernah dikirim',
          style: bodyStyle,
        ),
        const SizedBox(height: 18),
        for (final report in widget.controller.reports) ...[
          ReportStatusCard(report: report, onTap: () => _openDetail(report)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        const InfoNote('Data contoh. Laporan belum terhubung ke server.'),
      ],
    ),
  );
}

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({
    super.key,
    required this.report,
    required this.buildReportTimeline,
  });

  final ReportStatus report;
  final BuildReportTimeline buildReportTimeline;

  @override
  Widget build(BuildContext context) {
    final timeline = buildReportTimeline(report);

    return ScanSubpage(
      title: 'Detail laporan',
      selectedIndex: 4,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'URL yang dilaporkan',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                report.url,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ReportMetaRow(label: 'Jenis laporan', value: report.type),
        const SizedBox(height: 10),
        ReportMetaRow(
          label: 'Kategori dilaporkan',
          value: report.reportedCategory,
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Text(
                'Status',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: ReportStatusBadge(stage: report.stage),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ReportMetaRow(label: 'Waktu dikirim', value: report.submittedTime),
        if (report.notes != null) ...[
          const SizedBox(height: 20),
          const Text(
            'Catatan',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.paleBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              report.notes!,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Linimasa status',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < timeline.steps.length; i++) ...[
          ReportTimelineStep(
            label: timeline.steps[i],
            done: i <= timeline.activeIndex,
            isLast: i == timeline.steps.length - 1,
          ),
        ],
        const SizedBox(height: 20),
        const InfoNote('Data contoh. Linimasa menampilkan alur simulasi.'),
      ],
    );
  }
}
