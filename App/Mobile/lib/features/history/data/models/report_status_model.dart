import '../../../../data/demo_activity.dart';
import '../../domain/entities/report_status.dart';

/// Maps a stored report onto the entity the report screens render.
///
/// Two sources feed this model: the legacy example data used by previews and
/// the mobile API that returns the signed-in user's own reports.
class ReportStatusModel {
  const ReportStatusModel._({
    required this.url,
    required this.reportedCategory,
    required this.type,
    required this.stage,
    required this.submittedTime,
    this.id = '',
    this.submittedAt,
    this.notes,
  });

  factory ReportStatusModel.fromLegacy(ReportItem item) => ReportStatusModel._(
    url: item.url,
    reportedCategory: item.reportedCategory,
    type: item.type,
    stage: _legacyStage(item.status),
    submittedTime: item.submittedTime,
    notes: item.notes,
  );

  factory ReportStatusModel.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('Laporan tanpa URL.');
    }
    return ReportStatusModel._(
      id: (json['id'] ?? '').toString(),
      url: url,
      reportedCategory: (json['reported_category'] ?? '').toString(),
      type: (json['report_type'] ?? '').toString(),
      stage: _apiStage((json['status'] ?? '').toString()),
      submittedTime: _wibTime(json['created_at']),
      submittedAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      notes: switch (json['notes']) {
        final String value when value.trim().isNotEmpty => value,
        _ => null,
      },
    );
  }

  final String id;
  final String url;
  final String reportedCategory;
  final String type;
  final ReportStage stage;
  final String submittedTime;
  final DateTime? submittedAt;
  final String? notes;

  ReportStatus toEntity() => ReportStatus(
    id: id,
    url: url,
    reportedCategory: reportedCategory,
    type: type,
    stage: stage,
    submittedTime: submittedTime,
    submittedAt: submittedAt,
    notes: notes,
  );

  static ReportStage _legacyStage(String status) => switch (status) {
    'Selesai' => ReportStage.completed,
    'Ditinjau' => ReportStage.review,
    'Ditolak' => ReportStage.rejected,
    _ => ReportStage.submitted,
  };

  /// Statuses the mobile reports endpoint returns.
  static ReportStage _apiStage(String status) => switch (status) {
    'review' => ReportStage.review,
    'completed' => ReportStage.completed,
    'rejected' => ReportStage.rejected,
    _ => ReportStage.submitted,
  };

  /// The API stores UTC timestamps; the report screens show Indonesian time.
  static String _wibTime(Object? value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) return '-';
    final wib = parsed.toUtc().add(const Duration(hours: 7));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hour = wib.hour.toString().padLeft(2, '0');
    final minute = wib.minute.toString().padLeft(2, '0');
    return '${wib.day} ${months[wib.month - 1]} ${wib.year}, $hour:$minute WIB';
  }
}
