/// Summary shown on the home screen; legacy detail data stays in its feature.
class RecentScan {
  const RecentScan({
    required this.id,
    required this.url,
    required this.category,
    required this.isSafe,
    required this.scanTime,
  });

  final String id;
  final String url;
  final String category;
  final bool isSafe;
  final String scanTime;
}
