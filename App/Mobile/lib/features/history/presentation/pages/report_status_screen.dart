import '../../../../widgets/load_view.dart';

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
  void _openDetail(ReportStatus report) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReportDetailScreen(
        report: report,
        buildReportTimeline: widget.controller.buildReportTimeline,
        isSimulated: widget.controller.isSimulated,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LoadView(
    controller: widget.controller,
    kind: 'reports',
    subpage: true,
    builder: (context) => ScanSubpage(
      title: 'Status laporan',
      selectedIndex: 4,
      children: [
        Text(
          'Pantau proses peninjauan laporan yang telah Anda kirim.',
          style: TextStyle(
            fontSize: 13,
            color: context.colors.muted,
            height: 1.7,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.controller.reports.length} laporan pernah dikirim',
          style: TextStyle(fontSize: 11, color: context.colors.muted),
        ),
        const SizedBox(height: 8),
        if (widget.controller.reports.isEmpty)
          const InfoNote('Belum ada laporan yang dikirim.'),
        for (final report in widget.controller.reports) ...[
          ReportStatusCard(report: report, onTap: () => _openDetail(report)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        if (widget.controller.isSimulated)
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
    this.isSimulated = true,
  });
  final ReportStatus report;
  final BuildReportTimeline buildReportTimeline;
  final bool isSimulated;
  @override
  Widget build(BuildContext context) {
    final timeline = buildReportTimeline(report);
    return ScanSubpage(
      title: 'Detail laporan',
      selectedIndex: 4,
      children: [
        Text(
          report.url,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        ReportStatusBadge(stage: report.stage),
        const SizedBox(height: 24),
        ReportMetaRow(
          label: 'Jenis laporan',
          value: report.type == 'False Positive'
              ? 'Positif palsu'
              : 'Negatif palsu',
        ),
        const SizedBox(height: 14),
        ReportMetaRow(
          label: 'Kategori koreksi',
          value: categoryLabel(report.reportedCategory),
        ),
        const SizedBox(height: 14),
        ReportMetaRow(label: 'Waktu dikirim', value: report.submittedTime),
        if (report.notes != null) ...[
          const SizedBox(height: 24),
          const Text('Catatan', style: sectionTitleStyle),
          const SizedBox(height: 10),
          Text(
            report.notes!,
            style: TextStyle(
              fontSize: 13,
              color: context.colors.muted,
              height: 1.7,
            ),
          ),
        ],
        const SizedBox(height: 28),
        const Text('Linimasa status', style: sectionTitleStyle),
        const SizedBox(height: 20),
        for (var i = 0; i < timeline.steps.length; i++)
          ReportTimelineStep(
            label: timeline.steps[i],
            done: i <= timeline.activeIndex,
            isLast: i == timeline.steps.length - 1,
          ),
        if (isSimulated)
          const InfoNote('Data contoh. Linimasa menampilkan alur simulasi.'),
      ],
    );
  }
}
