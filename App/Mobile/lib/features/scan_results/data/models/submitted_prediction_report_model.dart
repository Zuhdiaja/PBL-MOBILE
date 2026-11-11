import '../../domain/entities/prediction_report.dart';

/// Maps the `report` object returned by the mobile reports endpoint.
class SubmittedPredictionReportModel {
  const SubmittedPredictionReportModel({
    required this.id,
    required this.status,
  });

  factory SubmittedPredictionReportModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const ScanResultsFailure('Respons server tidak dikenali.');
    }
    return SubmittedPredictionReportModel(
      id: id,
      status: (json['status'] ?? 'submitted').toString(),
    );
  }

  final int id;
  final String status;

  SubmittedPredictionReport toEntity() =>
      SubmittedPredictionReport(id: id, status: status);
}
