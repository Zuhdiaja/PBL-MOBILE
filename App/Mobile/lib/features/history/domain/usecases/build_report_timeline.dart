import '../entities/report_status.dart';

/// Builds the status timeline shown on the report detail page.
class BuildReportTimeline {
  const BuildReportTimeline();

  static const steps = ['Laporan dikirim', 'Sedang ditinjau', 'Selesai'];

  ReportTimeline call(ReportStatus report) => ReportTimeline(
    steps: steps,
    activeIndex: switch (report.stage) {
      ReportStage.submitted => 0,
      ReportStage.review => 1,
      ReportStage.completed => 2,
    },
  );
}
