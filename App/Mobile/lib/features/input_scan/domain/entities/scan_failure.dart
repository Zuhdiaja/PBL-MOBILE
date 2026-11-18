/// Why a scan could not be completed.
///
/// The kind lets callers decide whether to continue with the remaining URLs
/// (a single bad URL) or stop the whole submission (an expired session).
enum ScanFailureKind { auth, model, rateLimit, validation, network, unknown }

/// Failure raised while a URL is being checked.
class ScanFailure implements Exception {
  const ScanFailure(this.message, {this.kind = ScanFailureKind.unknown});

  final String message;
  final ScanFailureKind kind;

  /// True when continuing with the other URLs cannot succeed.
  bool get isFatal => kind == ScanFailureKind.auth;

  @override
  String toString() => message;
}
