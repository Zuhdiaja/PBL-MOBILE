import '../../../../presentation/load_controller.dart';
import '../../domain/entities/recent_scan.dart';
import '../../domain/repositories/recent_scans_repository.dart';

class HomeController extends LoadController {
  HomeController(this.repository, {this.isSimulated = true});
  final RecentScansRepository repository;

  /// True while the list comes from example data instead of the API.
  final bool isSimulated;
  List<RecentScan> _recentScans = const [];
  List<RecentScan> get recentScans => _recentScans;

  @override
  Future<void> load() => loadValue(
    repository.getRecentScans,
    (value) => _recentScans = List.unmodifiable(value),
  );

  Future<void> refresh() => refreshValue(
    repository.getRecentScans,
    (value) => _recentScans = List.unmodifiable(value),
  );
}
