import '../../../../data/demo_activity.dart';
import '../../domain/entities/report_status.dart';

/// Maps the legacy report model onto the report entity.
class ReportStatusModel {
  const ReportStatusModel(this.item);

  final ReportItem item;

  ReportStatus toEntity() => ReportStatus(
    url: item.url,
    reportedCategory: item.reportedCategory,
    type: item.type,
    stage: _stageOf(item.status),
    submittedTime: item.submittedTime,
    notes: item.notes,
  );

  static ReportStage _stageOf(String status) => switch (status) {
    'Selesai' => ReportStage.completed,
    'Ditinjau' => ReportStage.review,
    _ => ReportStage.submitted,
  };
}
