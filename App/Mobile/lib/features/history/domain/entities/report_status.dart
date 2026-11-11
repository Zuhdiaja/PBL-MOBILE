/// Progress of one submitted report.
enum ReportStage {
  submitted('Diproses'),
  review('Ditinjau'),
  completed('Selesai'),
  rejected('Ditolak');

  const ReportStage(this.label);

  /// Text shown to the user.
  final String label;
}

/// A report the user sent for one URL.
class ReportStatus {
  const ReportStatus({
    this.id = '',
    required this.url,
    required this.reportedCategory,
    required this.type,
    required this.stage,
    required this.submittedTime,
    this.submittedAt,
    this.notes,
  });

  /// Identifier of the stored report; empty for example data.
  final String id;
  final String url;
  final String reportedCategory;

  /// 'False Positive' atau 'False Negative'.
  final String type;
  final ReportStage stage;
  final String submittedTime;

  /// Submission time as returned by the API, used to group notifications.
  final DateTime? submittedAt;
  final String? notes;
}

/// Ordered timeline of the stages a report walks through.
class ReportTimeline {
  const ReportTimeline({required this.steps, required this.activeIndex});

  final List<String> steps;

  /// Index of the last stage the report has reached.
  final int activeIndex;
}
