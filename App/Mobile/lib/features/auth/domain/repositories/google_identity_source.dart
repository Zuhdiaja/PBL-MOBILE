/// Tokens handed back by the platform Google flow.
///
/// Mobile and emulator flows provide an ID token. The web flow can only
/// provide an access token, which the API verifies through Google directly.
class GoogleTokens {
  const GoogleTokens({this.idToken, this.accessToken});

  final String? idToken;
  final String? accessToken;

  bool get isEmpty =>
      (idToken == null || idToken!.isEmpty) &&
      (accessToken == null || accessToken!.isEmpty);
}

/// Obtains Google tokens from the platform.
///
/// Implementations live in the data layer: the real one wraps the
/// `google_sign_in` plugin, while tests and unconfigured builds use one that
/// returns nothing.
abstract class GoogleIdentitySource {
  /// The tokens, or an empty [GoogleTokens] when the user cancels.
  Future<GoogleTokens> obtainTokens();
}
