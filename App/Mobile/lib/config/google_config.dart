/// Web OAuth client ID, supplied at build time:
/// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=....apps.googleusercontent.com`
const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

/// Whether the Google button may be enabled on this build.
bool get googleSignInConfigured => googleWebClientId.isNotEmpty;
