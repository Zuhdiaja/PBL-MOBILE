import '../../domain/entities/prediction_report.dart';

/// In-memory example source for corrections while no service is connected.
class DemoPredictionReportDataSource {
  const DemoPredictionReportDataSource({this.delivers = true});

  static const categories = [
    'Aman / Benign',
    'Phishing',
    'Malware',
    'Spam',
    'Lainnya',
  ];

  /// Simulates a source that rejects writes.
  final bool delivers;

  List<String> readCategories() => categories;

  bool write(PredictionReport report) => delivers;
}
