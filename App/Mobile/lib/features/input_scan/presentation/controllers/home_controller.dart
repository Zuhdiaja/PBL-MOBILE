import '../../../../presentation/load_controller.dart';
import '../../domain/entities/recent_scan.dart';
import '../../domain/repositories/recent_scans_repository.dart';

class HomeController extends LoadController {
  HomeController(this.repository);
  final RecentScansRepository repository;
  List<RecentScan> _recentScans = const [];
  List<RecentScan> get recentScans => _recentScans;

  @override
  Future<void> load() => loadValue(
    repository.getRecentScans,
    (value) => _recentScans = List.unmodifiable(value),
  );
}
