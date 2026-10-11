import '../../domain/entities/recent_scan.dart';
import '../../domain/repositories/recent_scans_repository.dart';

class HomeController {
  HomeController(RecentScansRepository repository)
    : recentScans = List.unmodifiable(repository.getRecentScans());

  final List<RecentScan> recentScans;
}
