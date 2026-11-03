/// Obtains a Google ID token from the platform.
///
/// Implementations live in the data layer: the real one wraps the
/// `google_sign_in` plugin, while tests and unconfigured builds use one that
/// returns null.
abstract class GoogleIdentitySource {
  /// The ID token, or null when the user cancels or Google is unavailable.
  Future<String?> obtainIdToken();
}
