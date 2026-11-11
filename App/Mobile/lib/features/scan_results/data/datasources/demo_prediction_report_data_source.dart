import '../../domain/entities/prediction_report.dart';
import '../models/submitted_prediction_report_model.dart';
import 'prediction_report_data_source.dart';

/// In-memory example source for corrections while no service is connected.
class DemoPredictionReportDataSource implements PredictionReportDataSource {
  const DemoPredictionReportDataSource({this.delivers = true});

  /// Categories the API accepts, spelled as the report form shows them.
  static const categories = [
    'Aman / Benign',
    'Phishing',
    'Malware',
    'Spam',
    'Defacement',
    'Exploit',
  ];

  /// Simulates a source that rejects writes.
  final bool delivers;

  @override
  List<String> readCategories() => categories;

  @override
  Future<SubmittedPredictionReportModel> write(PredictionReport report) async {
    if (!delivers) {
      throw const ScanResultsFailure('Laporan belum dapat dikirim. Coba lagi.');
    }
    return const SubmittedPredictionReportModel(id: 1, status: 'submitted');
  }
}
