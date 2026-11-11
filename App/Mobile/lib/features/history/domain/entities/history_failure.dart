/// Failure raised while reading the user's activity from the API.
class HistoryFailure implements Exception {
  const HistoryFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
