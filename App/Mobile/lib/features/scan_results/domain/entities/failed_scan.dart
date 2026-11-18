/// A URL that could not be checked, kept next to the successful results so
/// the user sees exactly which link needs another try.
class FailedScan {
  const FailedScan({required this.url, required this.message});

  final String url;
  final String message;
}
