import '../entities/report_status.dart';

/// Builds the status timeline shown on the report detail page.
class BuildReportTimeline {
  const BuildReportTimeline();

  static const steps = ['Laporan dikirim', 'Sedang ditinjau', 'Selesai'];
  static const rejectedSteps = [
    'Laporan dikirim',
    'Sedang ditinjau',
    'Ditolak',
  ];

  ReportTimeline call(ReportStatus report) => switch (report.stage) {
    ReportStage.submitted => const ReportTimeline(steps: steps, activeIndex: 0),
    ReportStage.review => const ReportTimeline(steps: steps, activeIndex: 1),
    ReportStage.completed => const ReportTimeline(steps: steps, activeIndex: 2),
    ReportStage.rejected => const ReportTimeline(
      steps: rejectedSteps,
      activeIndex: 2,
    ),
  };
}
